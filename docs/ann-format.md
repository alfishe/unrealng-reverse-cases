# The annotation file (`.ann`)

A case's sources are generated, not typed. One annotation file per code image (`src/game/game.ann` for the game,
`src/<part>/<part>.ann` for the other parts on the medium) holds everything the reverse knows about the image:
modules, entries, names, titles, descriptions, comments, data shapes and resources. A generator reads it with the
image and the recordings' L1 builds, writes the `.asm`, assembles it with sjasmplus, and installs it only when the
bytes are the original's. **Edit the `.ann`, never the generated `.asm`.**

This document describes the format as the code parses it: `kit/mkgame.py` (class `Annotations`, the reference
parser, the one generator of every case's parts), `kit/refdocs.py`, `kit/ann_names.py` and `kit/sig_add.py`
(section 5: parts, banks and pieces). Where the file lives in a case and what it produces is in [case-files.md](case-files.md). The steps are
in [recipe 05](../recipes/05-source.md).

## Why a format of its own, not a SkoolKit control file

The `.ann` does not replace SkoolKit. It sits one level above it: `kit/mkgame.py` turns the `.ann` into a plain
SkoolKit control file (`work/mkgame/game.ctl`, section 4 step 3) and runs `sna2skool.py` and `skool2asm.py` on it. So
a case still has a standard control file, and any SkoolKit tool can read it. The `.ann` exists because a control
file alone cannot hold what a case needs:

| A case needs | In a control file | In the `.ann` |
| --- | --- | --- |
| Sources split into modules, each with a header (`render.asm`, `sound.asm`, ...) | one listing, no files | `@module`, `@about` (section 2) |
| An sjasmplus build that is checked against the original bytes and installed only when they match | `skool2asm.py` writes a listing, with no build and no check | the generator assembles, compares and installs only when identical (section 4, steps 6-7) |
| Only what the reverse knows: entries, names, titles | a block for every stretch of bytes, its kind given by hand, each time code and data meet | entries and names only. The code and data boundaries and the CALL targets come from the recordings' L1 builds and the static walk (section 4, step 2) |
| Resources as files you can edit (pictures, fonts, texts) | inline `DEFB` lines | `@res`: the bytes go to `src/res/`, and the case's `res_formats.py` turns them into PNG or text |
| Operands written as names: `Label+offset`, constants, variables past the image, strings after a `CALL`, code loaded over the caller | not as directives; you write it by hand in the skool file, or the listing shows bare numbers | section 3.4, `@isub`, `@equ`, `@inline`, `@over` |
| 128K banks and parts: several images, banked addresses, pieces | one 64 K snapshot per control file | `@bank`, `@piece`, part files (section 5) |
| Generated docs and signatures from the same names | no | `kit/refdocs.py` (docs 11, 12) and `kit/sig_add.py` read the `.ann` and the `.ctl` it produced |

**The cost.** The format is the repository's own. A tool from outside reads `work/mkgame/game.ctl` (made on every
`mkgame` run) or calls the reference parser (`kit/mkgame.py`, class `Annotations`); never write a second parser.
The way back exists as well: `kit/ctl2ann.py` turns the `draft.ctl` of an unreal-ng `re_session` export into a
first `.ann` (section 6). It reads the SkoolKit control syntax, so a third-party disassembly's `.ctl` is a candidate
input too, but no case has run it on one yet.

## 1. Lines

The parser reads the file line by line. Leading and trailing spaces are dropped.

| Line starts with | Is |
| --- | --- |
| empty | nothing |
| `#` | a comment for the reader of the `.ann`. It is never written to the `.asm`. The older form of the part directives (`# @bank`, `# @var`, ...) is read behind it too (section 5.1) |
| `@module`, `@about`, `@res`, `@isub`, `@inline`, `@equ` | a directive (section 2) |
| `@const`, `@bank`, `@names`, `@var`, `@alias`, `@over`, `@piece` | a part directive (section 5.1) |
| `>` | a description paragraph of the last entry |
| `$ADDR` | an entry or an inner line (section 3) |
| anything else | an error: `game.ann:N: cannot read: ...` |

Addresses are always four hex digits after a `$` (`$A56A`, not `$a56a0` or `0xA56A`). Lower case works in entry
lines, but `kit/ann_names.py` only matches upper case, so write upper case.

## 2. Directives

| Directive | Grammar | What the generator does with it |
| --- | --- | --- |
| `@module` | `@module NAME [; title]` | The entries from the next entry line on go to `NAME.asm`. The title heads that file and the `INCLUDE` line in `game.asm`. The module starts at its first entry, which must have a name, or `split_modules` fails. A module named like the top file that includes the modules (`@module game` beside `game.asm`) goes to `NAME-module.asm` (`game-module.asm`); its name stays `game` in the headers, docs 11 / 12 and the signatures. A module with no entry fails. The same name again further on adds a stretch to that module (an IM 2 handler at `$F70B` and its jump and vector table at `$FCFC`-`$FE00` with other modules between): one file, the stretches in address order, the second and later ones opened by `ORG $ADDR` where the assembly does not already stand; `game.asm` includes the file where its first stretch lies, the title is the first `@module` line's (a later line's title only when the first had none), `@about` lines add to the one header, docs 11 / 12 give the module one section with all its stretches, `kit/sig_add.py` one signature entry a stretch. Not in a part segment assembled under `DISP` (mkgame refuses it there) |
| `@about` | `@about text` | One paragraph of the current module's file header (wrapped at 116 columns between two rule lines). It is an error before any `@module` |
| `@res` | `@res KIND/NAME.bin` | The last entry, which must be a data entry, is a resource. Its bytes go to `src/res/KIND/NAME.bin` and its data lines become `INCBIN "res/KIND/NAME.bin",offset,length` (their comments go with them, the lines a long comment wraps onto too). Several entries naming one file share it: the file holds the bytes from the first entry to the end of the last. In a `w` entry, a word skool2asm wrote as a data label (`DEFW TileData`) is kept as a check after the `INCBIN`s, `ASSERT {TileGraphics} == TileData`, one line per `DEFW` line: the build fails when the label moves and the bytes do not (a word equal to a code label's address, `$0000` or `$FFFF` is taken for a number: data that matches an instruction's address, an end mark). The case's `tools/res_formats.py install(files)` turns the bytes into the editable source (PNG, text) at `--install`; a `NAME.bin` an earlier install left beside the editable form it now writes is deleted. `@res KIND/NAME.bin include`: the entry's lines become `INCLUDE "res/KIND/NAME.inc"` instead, a file the case's `res_formats.py build` writes from the editable form with `kit/resinc.py` (`DB` lines, a `DW Label` for an address, so sjasmplus resolves it and a moved label is followed; the entry's inner labels as labels inside it): the text stays the source, an address in it can be a name. `resinc.Symbols` gives a case's editable form the names both ways: `word($CCDA)` is `SharedModels+591` (the label at or below inside its entry, `Label+N`, else `$XXXX`), `value('SharedModels+591')` the address again (Battle Command's 3D models and mission `model` lines). One entry a file. mkgame checks its own assembly with a numeric `.inc` of the image's bytes (and installs that one beside the bytes for a case without a res hook) |
| `@isub` | `@isub $ADDR INSTRUCTION` | The instruction at `ADDR` is written exactly so: no `Label+offset`, `@equ` or `@var` name rewrites it. Use it for a constant the bytes cannot tell from an address (`LD HL,-6`, `LD SP,$FFFF`) and for an operand that needs a name the kit cannot work out (`LD HL,LevelTable-8`). A number equal to a label's address stays a number (skool2asm would write the label; the kit puts the instruction back as written), and a decimal number stays decimal (`LD DE,-10000`, which skool2asm writes `LD DE,-$2710`; `LD DE,1*256+30`). An `@isub` on an address that is no instruction fails: `@isub on no instruction: $XXXX` |
| `@inline` | `@inline $ADDR [N]` | The routine at `ADDR` reads data placed after its `CALL` (a print routine with an inline string). The static walk stops at every call to it, so a string no recording printed is not taken for code. With `N`, the routine reads exactly `N` bytes (a one-byte code, a column): the walk goes on after them, and only those bytes are data |
| `@equ` | `@equ $ADDR NAME [N] [at $I[,$J ...]] [; comment]` | A variable outside the image (the work space past the loaded bytes). The top file gets `NAME EQU $ADDR`, and every instruction operand in `ADDR..ADDR+N-1` is written `NAME` / `NAME+k` (not in an `@isub`'s instruction: `@isub $94C5 LD HL,$4010` stays a number inside `@equ $4000 Screen 6144`). N defaults to 1. With `at`, only the operands of the instructions at `$I`, `$J`, ... are named: an address that is also a plain number elsewhere (`@equ $0000 RomStart at $XXXX` names the `JP $0000` at `$XXXX` and leaves every `LD HL,$0000` alone). An `at` address that is no instruction fails: `@equ ... at no instruction: $XXXX`. An address inside the image is refused: name it as a label instead. Two operands are never named: the offset of a `Label+offset` (`LD HL,data_96FE+$4455` stays so inside `@equ $4000 Screen 6144`), and a port, the `LD BC,nn` whose `BC` feeds `IN` or `OUT (C)` (section 3.4; mkgame prints `port: $7178 LD BC,$FEFE feeds IN / OUT (C): kept a number, not Im2Table+254`); an `at` list that names the instruction still names it |

Real lines (Zynaps, `src/game/game.ann`):

```text
@module leveldata ; The level data: enemy paths, waves, kinds, the level table and scripts, the scenery
@about All the level data is one resource, src/res/levels/levels.lev.txt (tools/res_levels.py, ...).
@isub $B078 LD HL,LevelTable-8
@isub $897F LD DE,-32
```

## 3. Entries and inner lines

Both forms are matched by one pattern (`mkgame.ANNOTATION`):

```text
$ADDR [KIND] [NAME] [N] [; text]
```

### 3.1 An entry: `$ADDR KIND NAME [N] ; title`

When KIND is present the line opens an **entry**: a routine or a data block that runs up to the next entry.

| Kind | Is | N | SkoolKit block |
| --- | --- | --- | --- |
| `c` | code | (none) | `c` |
| `b` | bytes | bytes a `DEFB` line | `B` |
| `w` | words | words a `DEFW` line | `W` |
| `t` | text | (ignored) | `T` (`DEFM`) |
| `s` | space (zeros or don't-care fill) | (ignored) | `S` (`DEFS`) |

- NAME is the label, in PascalCase (`ann_names.py` enforces `[A-Z][A-Za-z0-9]*`). An entry without a name gets
  `sub_XXXX` (a CALL target), `l_XXXX` or `data_XXXX`. A finished case has none of these left.
- The text after `;` is the entry's **title**. It heads the entry in the `.asm` and is the title of the entry in
  docs 11 and 12, and the `summary` of a signature entry.
- An address given twice as an entry fails.
- A `c` entry is a **seed** of the code walk. The walk starts there even if no recording ran it, which is how a
  handler reached only through a table becomes code.
- The kind must agree with the recordings: a `b` entry where a recording ran an instruction fails with
  `$XXXX is b, the recordings say code` (and the other way round).

### 3.2 A description: `> text`

Each `>` line is one paragraph of the last entry's description. It goes to the `.asm` as the entry's `D` block,
to docs 11 / 12 (`refdocs.py`, hex addresses put in code spans), and nowhere else. Write what the routine does, its
inputs, outputs and side effects, with the evidence: the recording, the frame and the count.

```text
$6800 b PathStarts 14 ; The start of each of the 28 enemy paths: (address - $681C) / 2
> LaunchWave $91EC: E = PathStarts[the path number], the path pointer (record +$1D/+$1E) = $681C + 2E ...
@res levels/levels.bin
```

**Witness counts.** In a `c` entry's description, `Witness: L1 N (builds)` is checked by mkgame on every run: N must
be the runs of the entry's first instruction summed over the part's recordings (the game: `ref_builds`,
`read_builds`, `code_builds` and `witness_builds` of `case.json`, less `witness_skip`; a part: its `l1` and its
`witness_builds`), and the list the builds that ran it, each by its name (`stage1/c1` is `c1`, `stage2/rzx04/cap`
is `rzx04`: the second part of the build's path, else the whole; the part after `rec` (`stage2/rec/fuel` is `fuel`);
`case.json` `witness_names` `{"stage1/c1g": "c1"}` gives a windowed copy of a recording its name), sorted, a
numbered family of two or more builds in the set as one item (`rzx x32`): `Witness: L1 90104 (c1, hiscore, lives,
menu, timer, rzx x32).` A line that no longer agrees, say after `case.json` swaps a build, is printed:
`witness: src/game/game.ann:134 $8040 PrintGlyph: L1 90100 (c1, rzx x32), the builds give L1 90104 (...)`;
`mkgame.py --fix-witness` rewrites N and the list in the `.ann` (the rest of the line stays) and writes the source
again from it (with `--install` one run leaves the `.asm` current too); a line that names a
build mkgame did not load is kept as written and printed (`kept: NAME not among the builds`), and a name it drops is
printed as `NAME ran no instruction there`. Other witness text
(`Witness: L1 18 585 passes`, `Witness: L1 window ...`) is not touched.

### 3.3 An inner line: `$ADDR [NAME] [; comment]`

Without KIND the line names or comments an address **inside** an entry.

- In code: NAME is a label on that instruction (a loop, a branch target) and the comment goes on it.
- In data: the line **cuts the entry's rows** at ADDR. The data line that starts there carries the comment, and NAME
  becomes a label on it. This is how a field of a table gets its own name and comment.
- Two lines for one address merge (a name on one, a comment on the other). Two different names for one address
  fail.
- On a data entry's first address, a name other than the entry's is the record's **first field**: a second label
  after the entry's (`PlayerVars:` then `PocketTurn:`). An `LD` through memory at that address (`LD A,($9F43)`,
  `LD ($9F43),HL`) is written with the field's name, every other operand (`LD HL,$9F43`) with the entry's.
- Inside an `@res` entry an inner label splits the `INCBIN` there. The label must lie inside the entry, or the
  generator fails with `... inside the resource ... has no address in it`. In an `@res ... include` entry the label
  goes inside the `.inc` (mkgame's numeric one at its offset; the case's res tool writes it from the editable form,
  SimCity's menus as `label NAME`, `{=NAME}` or `NAME=V`).

```text
$66E0 BigSpriteGlyphs ; 8-byte linear glyphs read by BuildBigSprite $8F0C when A = 1 (the operand at $8F15)
$90A4 BuildStripsDone ; LD SP,n: n = the caller's SP
```

`python3 kit/ann_names.py --case C CF65=SetRestart CF8A=FreeRecordsLoop` writes inner names for you. It puts the
name on an existing comment line for that address, or inserts `$ADDR Name` after the nearest line below it. It
refuses an entry address, a name already used and a non-PascalCase name. Then run the generator again.

### 3.4 What becomes `Label+offset`

An operand that is always an address and has no label of its own is written as `Label+offset`, using the nearest
label at or below it in the same entry (`label_inner_addresses`):

- an `LD` through memory, `(nn)` on either side with any register (`LD A,($xxxx)`, `LD ($xxxx),A`,
  `LD BC,($xxxx)`);
- the `LD` of an address register: `LD HL,$xxxx`, `DE`, `IX`, `IY`, `SP`;
- `LD BC,$xxxx` when `BC` is a pointer: an instruction among the next 12 of the entry reads or writes through `(BC)`
  before `BC` changes or the flow leaves (`bc_is_pointer`);
- a `JP`, `CALL`, `JR` or `DJNZ` target that is not an instruction start (a jump into another instruction's
  operand, into a data entry); a target that is one has its own label.

`LD BC,$xxxx` is as often a number as an address: a port (`LD BC,$7FFD` before `OUT (C),A`), a count (before `LDIR`
or `DEC BC`), an offset (before `ADD HL,BC`, `$D8F0` = -10000), two bytes used apart (`LD BC,$F401`: B = 244,
C = 1). None of these reads through `(BC)`, so they stay numbers. A pointer handed to a routine (`LD BC,nn` then
`CALL`) is not seen: it needs `@isub` (Chuckie Egg's `@isub $AA9A LD BC,InstructionsText+102`).
`"operands": "wide"` (`--wide`) takes every `LD BC,nn` into an entry, for a part where all of them are pointers;
`"operands": "narrow"` (`--narrow`) takes none. SkoolKit names an `LD BC,nn` whose nn has a label of its own, but
not a port: an `LD BC,nn` whose `BC` an `IN r,(C)`, `OUT (C),r` or a block `IN` / `OUT` uses among the next 12
instructions of the entry, before `BC` changes or the flow leaves (`port_loads`), keeps its number against a label,
`Label+offset` (with `"wide"` too) and `@equ` (Tujad's `$797F LD BC,$7EFE`, the SPACE half row, at ShiftGraphic4's
address). A constant that only looks like an address needs `@isub`. An operand outside the image needs `@equ` (or
`@const` / `@bank`, section 5.1).

## 4. What the generator does

`kit/mkgame.py` is the one generator for every code image of every case. It has three forms:

```bash
python3 kit/mkgame.py [--case C] [--config FILE] [--ann FILE] [--out DIR] [--install]   # the case's game (case.json)
python3 kit/mkgame.py [--case C] --part src/<part>/<name>.json [--install]               # a part file (section 5.2)
python3 kit/mkgame.py [--case C] --image BIN --org ADDR --ann FILE --top NAME --dest DIR [--install]   # one image
```

`--case` defaults to the current folder. Every form takes `--venv` and `--sjasmplus`; without them it uses
`$SKOOLKIT_VENV` and `$SJASMPLUS`, else what `kit/toolpaths.py` finds (docs/case-files.md 10). For the game:

1. **Image.** Runs `case.json` `image_cmd` if given, then reads `image`, which must be a 64 K file. `lo`..`hi` are
   the game's bytes.
2. **Code.** Every instruction start that the recordings ran with the image's bytes (instructions and routine
   entries), from `work/<build>/l1.json` of the builds `case.json` names: `read_builds` (their data reads count
   too) and `code_builds` (instructions only). No other recording is read; a named build that is missing is an
   error. Only pages listed in `bases` count. Then a static walk follows the branches the recordings did not take,
   from the ran instructions and the `c` entries. The walk stops at bytes read as data, at a call to an `@inline`
   routine, at an `@over` target, at a call to an `@bank` address, and where it would cut into a ran instruction.
3. **Control file.** Writes `work/mkgame/game.ctl` (SkoolKit): one block per entry (yours, or one the code/data
   boundary or a CALL target makes), the titles, the `D` descriptions, the data sub-blocks cut at the inner lines.
   `refdocs.py` reads this file later.
4. **SkoolKit.** `sna2skool.py -H -c game.ctl`, then the `Label+offset` (and first field, section 3.3) and
   `@isub` rewrites (the ports of section 3.4 are `@isub`s of their own number), then `skool2asm.py -H`. After that:
   `IXl`/`IXh` are upper-cased, the first fields get their labels, `@equ` and `@var` names are applied (to every
   instruction but the `@isub` ones; an `@equ ... at` only to its own instructions; never to a `Label+offset`'s
   offset), an `@isub` where skool2asm put a label for a number or hex for a decimal number is written as the `.ann` has it, and the bare `;`
   SkoolKit leaves on continued data lines is removed.
5. **Resources and modules.** Writes the `@res` files with their `INCBIN`s (and a `w` entry's `ASSERT`s, section
   2; not in a segment assembled under `DISP`, where `{address}` reads other bytes) or, for `@res ... include`, the
   `INCLUDE` of the `.inc` and a numeric `.inc` of the image's bytes to assemble against, then splits the listing into one
   file per `@module`, each with its header. `game.asm` = the `case.json` `header` lines, `DEVICE`, the `EQU`s (`@const`,
   `@equ`, `@bank`, `@alias`), the head, one `INCLUDE` per module, and `SAVEBIN "game.bin",lo,hi-lo`.
6. **Check.** Runs `sjasmplus --nologo --msg=war game.asm` in the work folder and compares `game.bin` with the image.
   It prints `assembled: identical to the original image` or the first differing address.
7. **Install** (`--install`, only when identical). Writes the modules and `game.asm` into `src/game` (`case.json`
   `dest`; a case whose `case.json` names `"main": "main"`, a program in `software/`, has `main.ann`, `main.asm` and
   `src/main`), and the resources through the json's `res_install`, else (a part file with no `res` folder of its own)
   `case.json`'s `res_install`, else the case's `tools/res_formats.py install`, or as bytes when the case has none
   of these. A part with resources and no way to install them prints `WARNING: N resources not installed`. It never deletes a file it does not write: only the modules the old `game.asm`
   included and the `.ann` no longer has, and a resource's `src/res/NAME.bin` that the case's hook did not write
   while it wrote `NAME.png` / `NAME.txt` beside it (an install from before the editable form: the build would read
   both).

`kit/refdocs.py --case C` then reads `work/mkgame/game.ctl` and the `.ann`, together with the `ref_builds` L1 files,
and writes doc 11 (data: readers and writers) and doc 12 (routines: runs, own T-states, callers, callees, memory,
ports, `docs/img/routines/<Label>.gif` and every `<Label>-<what>.gif` that exists). Run mkgame first. Doc 12 groups
by `@module`. A memory range is named by the label at or below its first byte, inner labels included
(`Label+offset`). The interrupt's acceptance (the IM 2 vector read, the return address pushed), which L1 books to the
interrupted instruction, is given to the handler, which doc 12 shows "Entered by" the interrupt rather than called.
The case's other recordings count too: their runs (a routine no `ref_builds` recording reached says "not reached in
`c1`; in the other recordings ...", one that it did gets a row "Runs (the other recordings)"), callers, callees and
ports (`read_builds` and `code_builds`), and their reads and writes (`read_builds` only: a `code_builds` recording's
reads may be a depacker's input). Doc 11 gives each inner label of a data entry a row under it (its size up to the
next label, its comment as the line says it, its own readers and writers). Its readers and writers are those of the
`ref_builds`, then those only another recording saw, with the first such build in brackets (`` `DrawCell`
(`stage2/rzx04/cap`) ``), then, marked "(code)", the routines whose `LD r,(nn)` / `LD (nn),r`, or an access through
`(HL)`, `(DE)` or `(BC)` after `LD HL,nn` (`DE`, `BC`) in the same block (no jump target, branch or call between, the
pair changed only by `INC` / `DEC`), in `work/mkgame/game.skool` reach the bytes where no recording saw them do so,
each named by the label at or below the instruction (`WalkIntoFire`, a label inside `UpSpecialCell`; left out when a
recording already names the routine it lies in) (kit/README.md,
"What refdocs.py writes").

`kit/sig_add.py ann --case C ...` cuts the image into the `.ann`'s modules and writes one signature entry per module.
The entry name is `<program>: <module>`, its entries are the named `c` entries with their titles, its labels the
data entries and inner names. `@equ` names name the external operands, and `@inline` routines stop its decoder. See
[signature-format.md](signature-format.md).

## 5. Parts, banks and pieces

The game is one part. Every other code image of a medium (a loader, a menu, a driver, a bank, a block of pieces
copied to their run addresses) is a part too, written by the same `kit/mkgame.py` from a part file or the command
line. One generator rather than one per case: the cases had nine copies and wrappers of the kit (a fork per need:
pages, banks, pieces, segments, traces), each fixing the same things again and drifting apart. One parser and one
pipeline keep every case on the same `.ann` format, and `kit/refdocs.py` and `kit/sig_add.py` read what it writes.

### 5.1 The part directives

These are directives of the kit's parser (`mkgame.Annotations`), in any `.ann`:

| Directive | Grammar | Does |
| --- | --- | --- |
| `@const` | `@const NAME VALUE [; comment]` (VALUE `$hex` or decimal) | `NAME EQU VALUE` in the top file: a port, a ROM entry, a page value, an address in another program (`@const GS_CMD $BB ; ...`). The instructions use it through `@isub` |
| `@bank` | `@bank $ADDR NAME BANK [; comment]` (BANK a number or a name: `1`, `DriverBank`), or `@bank $ADDR BANK [; comment]` after an `@names BANK` line | An address in another RAM bank paged at `$C000` (a player in bank 1, the disk module in bank 4). It becomes `NAME EQU $ADDR ; bank BANK: comment`, sorted by bank and address. The walk does not follow the instructions whose `@isub` names it, and the entry mark the disassembler puts on this image's byte there is dropped. `@equ` cannot do it: the address may be inside the image, and one address can mean different things in different banks. The short form takes NAME from the bank's `.ann` (`@names`): the entry or inner label at `$ADDR` there, so a name the bank defines is written once; an address that file does not name fails, and a long form whose NAME differs from it fails too |
| `@names` | `@names BANK PATH [; comment]` (PATH relative to this `.ann`) | The `.ann` of bank BANK (its own part): the names the short `@bank` lines read. Battle Command's `game.ann` has `@names 3 ../bank3/bank3.ann` (and 4, 6, 7), its 30 `@bank` lines say only `@bank $CA8B 3` |
| `@var` | `@var $ADDR NAME [N] [; comment]` | A variable inside the image's work space: a label in its data entry (the data line is cut there), and every instruction operand `ADDR+1..ADDR+N-1` written `NAME+k` |
| `@alias` | `@alias NAME EXPR [; comment]` | `NAME EQU EXPR` for a name that cannot be a label (the operand of a `JP` into a handler: `@alias Handler ImJump+1`). The instructions name it through `@isub` |
| `@over` | `@over $ADDR [; why]` | A branch target that holds other bytes when the branch runs (code loaded over the caller's strings): the walk does not follow it |
| `@piece` | `@piece NAME` | The lines from here to the next `@piece` are the piece `NAME`. A part file's segment with `"piece": "NAME"` reads the lines before the first `@piece` (common to all pieces) and that piece's. An `@equ` of the common lines inside the piece's own range is dropped there (it is that piece's label) |

The cases' first generators read `@bank`, `@var`, `@alias`, `@over` and `@piece` behind a `#` (`# @bank ...`);
the kit reads that form too, so existing `.ann` files need no edit. Write new lines without the `#`.

**One `.ann` for several parts.** Two part files may name the same `.ann` (`"ann"`), each with its own image: mkgame
keeps the entries inside the part's image and drops the rest with their descriptions, resources and `@isub` lines. A
module whose entries all lie outside the image is not in that part (mkgame prints
`module NAME ($ADDR) lies outside the image ...: not in this part`); a module that starts outside the image and holds an entry inside fails with the
module's name and address, as does a module whose first entry has no name (`split_modules`). Battle Command's loader
blocks 37 (`$BE5D`) and 39 (`$BF21`) share `src/loader/final.ann`: the common `@equ` lines once, the modules `final`
and `timeend`. `@piece` (below) is the other way: one image, pieces copied to their run addresses.

### 5.2 Part files

A part file (`src/<part>/<name>.json`) says what the image is and how it is cut. `kit/mkgame.py --part FILE`
runs it. One image with one `.ann` is the *single* layout (the top file is written like the game's):

```json
{"image": "build/trd/obj/boot-menu.bin", "org": "61A8",
 "ann": "src/trd/boot/menu.ann", "top": "boot-menu", "dest": "src/trd/boot", "res": "src/res/trd",
 "header": ["; Nether Earth GS, TRD file boot: the boot menu's menu part"],
 "mode": "blocks", "pages": [5, 2], "l1": ["work/stage2/trd/rA/l1.json"],
 "built": {"boot/texts.bin": "trd/text/trd-boot-menu.bin"}, "save": "build/trd/obj/boot-menu.bin"}
```

An image of several segments (each with its own `.ann` or piece, run address and banks, or raw lines another part's
source gives) is the *segments* layout: the top file sets `ORG` / `DISP` per segment and `INCLUDE`s
`<top>/<module>.asm` (or `<module>.asm` with `"subdir": false`), then `SAVEBIN`s the whole image:

```json
{"name": "deadend", "image": "build/endings/deadend-c000-bank3.bin", "at": "C000", "out": "build/endings/deadend-c000-bank3.bin",
 "dest": "src/endings", "l1": ["work/endings/de/l1.json"], "operands": "wide", "include": ["."],
 "segments": [{"lo": "C000", "hi": "D2EF", "lines": ["  MODULE nst", "  INCLUDE \"src/music/stp-player.asm\"", "..."]},
              {"ann": "src/endings/deadend.ann", "lo": "D2EF", "hi": "FE1F", "run": "D2EF",
               "bases": {"3": "C000"}, "read_builds": ["de"]}],
 "external": ["nst.Init", "nst.Play"]}
```

| Key | Meaning |
| --- | --- |
| `image`, `at` / `org` | the bytes and the address of byte 0 (a 64 K image needs neither). `image_cmd` (a command run in the case, every time; `"image_always": false`: only when the image is missing) makes it; `image_note` says what makes it when it is missing. A part may take its image from an earlier build step (`build/...`): the case's build checks that output against `orig/` |
| `lo`, `hi` | single layout: only these addresses of the image (hex, `hi` exclusive) |
| `ann`, `piece` | the annotations (and the piece of them) |
| `top` / `name`, `dest`, `bin` / `out` | the top file `TOP.asm`, where `--install` writes it and the modules, the `SAVEBIN` name |
| `header`, `written`, `device` | the top file's first comment lines, its "Written by" line (default: from the `.ann`), the sjasmplus `DEVICE` (`ZXSPECTRUM48`) |
| `witness_builds` | more recordings for the witness counts only (section 3.2): `work/<build>/l1.json` |
| `l1` | the recordings: `"PATH"` or `{"path", "reads", "lo", "hi", "roots", "format", "optional"}`. `reads`: its data reads count (not for a build over a depacker's input; default: the build's folder is in `read_builds`). `lo`/`hi`: only this window of addresses counts (the bytes that held this part while it ran). `roots: false`: a routine that is only the window's root (where the build began) is no entry. `format: "trace"`: a simulator's `{"starts": {ADDR: length}, "entries": [ADDR], "reads": {ADDR: count}}`. A path may be a glob. A segment's own `l1` replaces the part's |
| `mode` | `"instructions"` (default: every recorded instruction whose opcode and length are the image's) or `"blocks"` (only whole recorded basic blocks whose every instruction has the image's bytes, no routine entries: a later program at the same addresses cannot make a lone byte look like code) |
| `bases`, `pages`, `bank` | L1 page -> Z80 base (`{"5": "4000", "2": "8000", "0": "C000"}` by default); `pages` lists pages at their natural base (5 `$4000`, 2 `$8000`, any other `$C000`); `bank` N adds `SLOT 3` / `PAGE N` to the top file |
| `same_bytes` | count a recorded instruction only when all its bytes are the image's (code overwritten later in the same window) |
| `data_entries` | `"stop"` (or `true`): every annotated data entry, up to the next entry, is data the walk never enters; `"first"`: only the entry's first byte stops the walk |
| `entries_in_code`, `no_entries` | keep only the recorded routine entries the walk made code / take none |
| `overwritten` | `[[LO, HI], ...]`: ranges another block overwrites at run time; no recorded instruction there counts and the walk stops there |
| `operands` | `LD BC,nn` as `Label+offset` (section 3.4): only the pointers read through `(BC)` by default, `"wide"` every one, `"narrow"` none |
| `drop_data_refs`, `isub_as_written` | drop sna2skool's reference marks inside data rows; write `@isub` numbers as the `.ann` does (decimal), not as skool2asm's hex (now always so: the key stays for the older part files) |
| `res`, `res_install`, `built`, `save` | the resources: as bytes into `res` (the `INCBIN`s name it relative to `dest`), or through a hook `tools/x.py[:function]` called with `{name: bytes}` (no `res_install` and no `res`: `case.json`'s, else `tools/res_formats.py`, section 4 step 7); `built` `{NAME: PATH}` is a resource the build makes (not installed, `INCBIN "PATH"`); `save` is the installed top file's `SAVEBIN` path |
| `segments` | the segments layout: `{"ann", "piece", "lo", "hi", "run", "bases", "read_builds", "title", "load_label", "l1", ...}` (any key above may be set per segment) or `{"lo", "hi", "lines": [...]}` |
| `external`, `subdir`, `include`, `before_assemble` | names other included sources define (no `EQU` for them); modules in `dest/<top>/` (default) or `dest/`; `-I` folders for sjasmplus; a hook `tools/x.py:function` called with the work folder before sjasmplus |
| `work`, `clean_work` | the work folder (default `work/mkpart/<top>`) |

`case.json` takes the same keys for the game (`dest`, `work`, `res_install`, `operands`, `mode`, `no_entries`,
`entries_in_code`, `overwritten`, ...), and `witness_skip`: the builds left out of the witness counts (section 3.2;
Earth Shaker's two death recordings, which its `.ann` names where it uses them).

### 5.3 One image on the command line

`--image BIN --org ADDR` is the single layout without a file. It runs with `data_entries "stop"`,
`drop_data_refs` and `isub_as_written` on, the defaults of the part generators it replaced:

```bash
python3 ../../kit/mkgame.py --image work/parts/loader-5d3b.bin --org '$5D3B' --ann src/loader/loader.ann \
    --top zynapsb --dest src/loader --res src/res --l1 work/stage2/loader/l1.json --blocks \
    --page 5 --page 2 --page 0 --page 4 --title 'Zynaps 2 in 1: ZYNAPS.B sector 0 ($5D3B)' \
    --save build/obj/zynapsb-basic.bin --install
```

`--l1` (instructions only), `--l1-reads` (instructions and data reads), `--blocks`, `--page N` (repeat), `--bank N`,
`--range LO-HI`, `--built NAME=PATH`, `--save PATH`, `--res DIR`, `--wide`, `--narrow` are the keys above.

### 5.4 In the cases

| Case | Parts | How |
| --- | --- | --- |
| nether-earth, zynaps, hate | the game | `kit/mkgame.py --install` (`case.json`) |
| nether-earth-editor | `nee.mix` | `tools/mkmix.sh`: `--config src/mix/case.json` |
| zynaps-128 | the game; boot, intro, loader, depacker, sound, stubs, glue, setup, mouse | `tools/mkgame.sh`; `tools/mkasm_all.sh` (`--image --blocks` per part) |
| zynaps-gs | the game; `src/disk/{boot,screen,loader,menu,driver}` | `tools/regen.sh` (`--image --blocks --page N`) |
| nether-earth-gs | the game (`@bank`, `@var`, `@alias`); the TRD boot menu | `kit/mkgame.py --install`; `--part src/trd/boot/{menu,print64}.json` |
| nether-earth-zs-edition | nine parts: game99, patches99 (`@piece`, one segment a piece), game98, intro98, stage2, pictures99, music99, stage3, menu99 (`@over`) | `tools/regen.sh` (`--part src/<part>/<name>.json`) |
| battle-command | the game (`@bank` short form, `@names` of the four banks); banks 3, 4, 6, 7 (`"bank": N`); the tape BASIC, the decryption chain, loader stage 2, blocks 37 and 39 (one `final.ann`) | `tools/mkasm_all.sh` (`--case .`, `--part src/<part>/<name>.json`) |
| advanced-nether-earth | the game (`@bank`); the boot menu (simulator traces); the disk parts; the endings | `kit/mkgame.py --install`; `--part src/{bootmenu,disk,endings}/*.json`; the intro stays on `tools/intro_mkpart.py` |

The intro of Advanced Nether Earth keeps its own generator: its code comes from `tools/intro_trace.py`'s phased
simulator runs, each phase with its own bank map, and the runs that made the shipped sources are not recorded as
commands, so a part file could not be checked to give the same sources.

## 6. Starting and growing a `.ann`

1. **Empty first.** With `case.json` filled in (recipe 01) and at least one L1 build in `work/<build>/l1.json`
   (recipe 04), an `.ann` that holds only its header comment already works:
   `mkgame.py --case C ...` gives an image of `sub_` / `l_` / `data_` entries that assembles identically (Zynaps,
   WALKTHROUGH 4). Do not `--install` yet. Read `work/mkgame/game.ctl` and `work/mkgame/*.asm` for the cut the
   recordings give.
2. **The analysis as input.** The L1 routines (entries, callers, profile), L2 region kinds (graphics, text, tables)
   and the review queue (recipe 04) say what each region is. `re_session.py export --work W` writes
   `W/draft/draft.ctl`, `draft.skool`, `draft.map.txt`, `draft.fields.json` and the findings register. These are
   the start of the first `.ann`: `kit/ctl2ann.py` turns the draft's entries, kinds, titles, descriptions and the
   names it gave from evidence into `.ann` lines, and with `--case` makes `c` every draft data entry that starts on
   code the case's recordings ran (the draft is one build's, the case's code comes from all of them):

   ```bash
   cd games/hate        # tried on H.A.T.E.'s p2 draft: 682 entries, 162 code; assembles identical
   python3 ../../kit/ctl2ann.py work/p2/draft --case . --out work/ann/draft.ann
   python3 ../../kit/mkgame.py --ann work/ann/draft.ann --out work/ann/mk-draft
   ```

   The draft's generic names (`data_5B00`, `sub_8000`) are dropped (`--names pascal` keeps them as `Data5B00`), so
   the generator names by address until a person names the entry. Every title and description is the draft's guess
   until checked: rewrite them as the reverse proves each one.
3. **Seed from a base case** (derived case, [recipe 10](../recipes/10-derived-case.md)). Take the base case's
   `.ann` without the entries outside the image, drop the entries the version rewrote, and re-attribute the evidence
   ("Nether Earth's deep recording"). nether-earth-gs: `work/stage2/ann/seed_ann.py`. advanced-nether-earth:
   `work/stage3/aneg/seed_ann.py` from `ne_match.py`'s table. Every entry the version touched is written again.
4. **Fragments in parallel.** Cut the image into address ranges, one annotator each, each writing
   `work/ann/NN-*.ann` with a cross-reference of the addresses outside it and notes with the evidence. Prove each
   fragment alone: `kit/mkgame.py --case C --ann work/ann/NN-full.ann --out work/ann/mk-NN` (the header plus the
   fragment; the bytes identical). The lead merges the fragments (`work/merge/merge.py` in zynaps), renames the
   clashes and replaces test labels quoted in prose (`l_9954`) by the final names
   ([recipe 11](../recipes/11-agents.md)).
5. **Grow it.** Modules by subsystem (`@module` + `@about`), every routine named and described, inner labels with
   `ann_names.py`, data shapes (`b NAME 8`, `w`, `t`), `@res` for every resource, `@equ` for the work space,
   `@isub` for the constants. After each batch:

   ```bash
   python3 kit/mkgame.py --case games/<game> --venv $SKOOLKIT_VENV --sjasmplus $SJASMPLUS --install
   games/<game>/tools/build.sh $SJASMPLUS          # -> build: identical to orig/...
   python3 kit/refdocs.py --case games/<game>      # docs 11, 12
   ```

   A finished `.ann` has no `sub_` / `l_` / `data_` label left. `grep -c 'l_[0-9A-F]\{4\}' src/game/*.asm` must give 0.

## 7. Checking the regenerated `.asm`

- The generator itself refuses to install unless sjasmplus gives the original bytes. Then the case's
  `tools/build.sh` rebuilds the whole medium and compares it with `orig/` (`build: identical to ...`).
- After an edit that should change only comments (descriptions, titles, comments), `git diff --stat src/` must show
  only `.ann` and `.asm` comment lines, and the build stays identical.
- The `.asm` in git must be what the generator writes from the `.ann` in git. After a merge, run the generator
  again and check that `git status` shows no change to the `.asm`. A hand edit that was never put into the `.ann`
  is lost at the next run (H.A.T.E. WALKTHROUGH: two outputs had been corrected by hand).

## 8. Common mistakes

| Mistake | Symptom | Fix |
| --- | --- | --- |
| `@res` after a code entry, or before any entry | `@res after no data entry` | put it under the data entry it belongs to (after its `>` lines) |
| `@res` on an entry the walk made code, or an entry that ends early | `@res NAME on $XXXX, which is no data entry` | make it a `b` entry, check the kind against the recordings |
| A label inside an `@res` entry that is not its own inner line | `... inside the resource ... has no address in it` | an inner line `$ADDR Name` inside the entry |
| A kind that disagrees with the recordings | `game.ann: $XXXX is b, the recordings say code` | the recordings win. A real overlay (a buffer over code) goes in `case.json` `overlay` or a `read_builds` change, not a forced kind |
| The same name on two addresses, or two names on one | `named twice` / `already a name` | one name an address, unique over the file |
| `@module` before an unnamed entry | `module NAME starts at $XXXX, an entry with no name` | name the module's first entry |
| `@isub` on an address that is not an instruction start | `@isub on no instruction` | the address of the instruction's first byte |
| An `@equ` name on a number that is no address (`LD HL,$0000` named `RomStart`) | a count or a constant written as a name | `@equ ... at $I` with only the instructions that use the address (a port before `IN` / `OUT (C)` is kept a number by itself) |
| An inner name that is one letter `b`, `c`, `w`, `t` or `s` | read as a kind | longer names |
| A string after a `CALL` taken for code | odd instructions (`LD BC,$1704`) after the call | `@inline $ROUTINE` |
| An L1 build of the loader in `read_builds` | the game's code taken for data (the depacker read its packed input there) | only builds after the unpack in `read_builds` |
| A recording of another program in `work/*/l1.json` | stray entries or code in the image (`kit/mkgame.py` reads every `work/*/l1.json`) | keep such builds in a nested folder (`work/stage2/<window>/`) or use a part generator that takes `--l1` |
| A comment that reads well but no run checked it | a wrong statement in docs 11 / 12 (a "tune frequency", a "life lost") | name and describe only what a run confirms ([GUIDE](../GUIDE.md) 6) |
| Editing `src/game/*.asm` | the edit is lost at the next `--install` | edit the `.ann` |
