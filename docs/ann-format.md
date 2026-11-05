# The annotation file (`.ann`)

A case's sources are generated, not typed. One annotation file per code image (`src/game/game.ann` for the game,
`src/<part>/<part>.ann` for the other parts on the medium) holds everything the reverse knows about the image:
modules, entries, names, titles, descriptions, comments, data shapes and resources. A generator reads it with the
image and the recordings' L1 builds, writes the `.asm`, assembles it with sjasmplus, and installs it only when the
bytes are the original's. **Edit the `.ann`, never the generated `.asm`.**

This document describes the format as the code parses it: `kit/mkgame.py` (class `Annotations`, the reference
parser), `kit/refdocs.py`, `kit/ann_names.py`, `kit/sig_add.py`, and the cases' own generators that extend it
(section 5). Where the file lives in a case and what it produces is in [case-files.md](case-files.md). The steps are
in [recipe 05](../recipes/05-source.md).

## 1. Lines

The parser reads the file line by line. Leading and trailing spaces are dropped.

| Line starts with | Is |
| --- | --- |
| empty | nothing |
| `#` | a comment for the reader of the `.ann`. It is never written to the `.asm`. The case generators' extended directives (`# @bank`, `# @var`, ...) also live here, so `kit/mkgame.py` skips them (section 5) |
| `@module`, `@about`, `@res`, `@isub`, `@inline`, `@equ` | a directive (section 2) |
| `>` | a description paragraph of the last entry |
| `$ADDR` | an entry or an inner line (section 3) |
| anything else | an error: `game.ann:N: cannot read: ...` |

Addresses are always four hex digits after a `$` (`$A56A`, not `$a56a0` or `0xA56A`). Lower case works in entry
lines, but `kit/ann_names.py` only matches upper case, so write upper case.

## 2. Directives

| Directive | Grammar | What the generator does with it |
| --- | --- | --- |
| `@module` | `@module NAME [; title]` | The entries from the next entry line on go to `NAME.asm`. The title heads that file and the `INCLUDE` line in `game.asm`. The module starts at its first entry, which must have a name, or `split_modules` fails. `@module game` is refused because `game.asm` is the top file that includes the modules. A module with no entry fails |
| `@about` | `@about text` | One paragraph of the current module's file header (wrapped at 116 columns between two rule lines). It is an error before any `@module` |
| `@res` | `@res KIND/NAME.bin` | The last entry, which must be a data entry, is a resource. Its bytes go to `src/res/KIND/NAME.bin` and its data lines become `INCBIN "res/KIND/NAME.bin",offset,length`. Several entries naming one file share it: the file holds the bytes from the first entry to the end of the last. The case's `tools/res_formats.py install(files)` turns the bytes into the editable source (PNG, text) at `--install` |
| `@isub` | `@isub $ADDR INSTRUCTION` | The instruction at `ADDR` is written exactly so. Use it for a constant the bytes cannot tell from an address (`LD HL,-6`, `LD SP,$FFFF`) and for an operand that needs a name the kit cannot work out (`LD HL,LevelTable-8`). An `@isub` on an address that is no instruction fails: `@isub on no instruction: $XXXX` |
| `@inline` | `@inline $ADDR` | The routine at `ADDR` reads data placed after its `CALL` (a print routine with an inline string). The static walk stops at every call to it, so a string no recording printed is not taken for code |
| `@equ` | `@equ $ADDR NAME [N] [; comment]` | A variable outside the image (the work space past the loaded bytes). The top file gets `NAME EQU $ADDR`, and every instruction operand in `ADDR..ADDR+N-1` is written `NAME` / `NAME+k`. N defaults to 1. An address inside the image is refused: name it as a label instead |

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

### 3.3 An inner line: `$ADDR [NAME] [; comment]`

Without KIND the line names or comments an address **inside** an entry.

- In code: NAME is a label on that instruction (a loop, a branch target) and the comment goes on it.
- In data: the line **cuts the entry's rows** at ADDR. The data line that starts there carries the comment, and NAME
  becomes a label on it. This is how a field of a table gets its own name and comment.
- Two lines for one address merge (a name on one, a comment on the other). Two different names for one address
  fail.
- Inside an `@res` entry an inner label splits the `INCBIN` there. The label must lie inside the entry, or the
  generator fails with `... inside the resource ... has no address in it`.

```text
$66E0 BigSpriteGlyphs ; 8-byte linear glyphs read by BuildBigSprite $8F0C when A = 1 (the operand at $8F15)
$90A4 BuildStripsDone ; LD SP,n: n = the caller's SP
```

`python3 kit/ann_names.py --case C CF65=SetRestart CF8A=FreeRecordsLoop` writes inner names for you. It puts the
name on an existing comment line for that address, or inserts `$ADDR Name` after the nearest line below it. It
refuses an entry address, a name already used and a non-PascalCase name. Then run the generator again.

### 3.4 What becomes `Label+offset`

Inside an entry, an address operand of an `LD` (`LD HL,$xxxx`, `LD A,($xxxx)`, `LD ($xxxx),A`) that has no label of
its own is written as `Label+offset`, using the nearest label at or below it in the same entry
(`label_inner_addresses`). Other instructions (JP, CALL, JR) always target labels. A constant that only looks like
an address needs `@isub`. An operand outside the image needs `@equ` (or `@const` / `# @bank`, section 5).

## 4. What the generator does

`kit/mkgame.py --case C --venv VENV --sjasmplus BIN [--ann FILE] [--out DIR] [--install]` does the following:

1. **Image.** Runs `case.json` `image_cmd` if given, then reads `image`, which must be a 64 K file. `lo`..`hi` are
   the game's bytes.
2. **Code.** Every instruction start that the recordings ran with the image's bytes, taken from every
   `work/*/l1.json` (instructions and routine entries). Only pages listed in `bases` count. Data reads count only
   from the `read_builds`. Then a static walk follows the branches the recordings did not take, from the ran
   instructions and the `c` entries. The walk stops at bytes read as data, at a call to an `@inline` routine, and
   where it would cut into a ran instruction.
3. **Control file.** Writes `work/mkgame/game.ctl` (SkoolKit): one block per entry (yours, or one the code/data
   boundary or a CALL target makes), the titles, the `D` descriptions, the data sub-blocks cut at the inner lines.
   `refdocs.py` reads this file later.
4. **SkoolKit.** `sna2skool.py -H -c game.ctl`, then the `Label+offset` and `@isub` rewrites, then
   `skool2asm.py -H`. After that: `IXl`/`IXh` are upper-cased, `@equ` names are applied, and the bare `;` SkoolKit
   leaves on continued data lines is removed.
5. **Resources and modules.** Writes the `@res` files with their `INCBIN`s, then splits the listing into one file per
   `@module`, each with its header. `game.asm` = the `case.json` `header` lines, `DEVICE`, the `EQU`s, the head, one
   `INCLUDE` per module, and `SAVEBIN "game.bin",lo,hi-lo`.
6. **Check.** Runs `sjasmplus --nologo --msg=war game.asm` in `work/mkgame` and compares `game.bin` with the image.
   It prints `assembled: identical to the original image` or the first differing address.
7. **Install** (`--install`, only when identical). **Deletes every `src/game/*.asm`**, writes the modules and
   `game.asm`, and installs the resources through `tools/res_formats.py install`, or as bytes when the case has no
   such script.

`kit/refdocs.py --case C` then reads `work/mkgame/game.ctl` and the `.ann`, together with the `ref_builds` L1 files,
and writes doc 11 (data: readers and writers) and doc 12 (routines: runs, own T-states, callers, callees, memory,
ports, `docs/img/routines/<Label>.gif` when it exists). Run mkgame first. Doc 12 groups by `@module`.

`kit/sig_add.py ann --case C ...` cuts the image into the `.ann`'s modules and writes one signature entry per module.
The entry name is `<program>: <module>`, its entries are the named `c` entries with their titles, its labels the
data entries and inner names. `@equ` names name the external operands, and `@inline` routines stop its decoder. See
[signature-format.md](signature-format.md).

## 5. Extensions in the cases

The kit's generator takes one 64 K image, all of `work/*/l1.json`, and installs into `src/game`. Images that do
not fit that model (a part loaded elsewhere, several banks, pieces placed with `DISP`) have generators of their own
in the case's `tools/`. These are copied from a sibling case, never imported (the cases stay apart). They all import
`kit/mkgame.py`'s functions and add directives:

| Directive | Grammar | Generators | Does |
| --- | --- | --- | --- |
| `@const` | `@const NAME VALUE [; comment]` (VALUE `$hex` or decimal) | `zynaps-128/tools/part_mkasm.py`, `zynaps-gs/tools/part_mkasm.py`, `nether-earth-gs/tools/trd_mkasm.py`, `advanced-nether-earth/tools/bootmenu_mkasm.py` | An `EQU` in the part's top file: ports, ROM entries, page values, addresses outside the part (`@const GS_CMD $BB ; ...`, `@const PAGE_BANK7 $17`). The line is blanked before `mkgame.Annotations` reads the file, so the kit never sees it |
| `# @bank` | `# @bank $ADDR NAME BANK [; comment]` | `advanced-nether-earth/tools/game_mkgame.py`, `nether-earth-gs/tools/game_mkgame.py` | An address in another RAM bank paged at `$C000` (a player in bank 1, the disk module in bank 4). It becomes an `EQU`, the walk does not follow calls to it, and the entry mark on bank 0's byte there is dropped. The instructions name it through `@isub` (`@equ` cannot: the address may be inside the image, and one address can mean different things in different banks) |
| `# @var` | `# @var $ADDR NAME [N] [; comment]` | `nether-earth-gs/tools/game_mkgame.py` | A variable inside the image's work space: a label in its data entries, with operands `ADDR+1..ADDR+N-1` written `NAME+k` |
| `# @alias` | `# @alias NAME EXPR [; comment]` | the two `game_mkgame.py` | `NAME EQU EXPR` for a name that cannot be a label (the operand of a `JP` into a handler). The instructions name it through `@isub` |
| `# @over` | `# @over $ADDR ; why` | `nether-earth-zs-edition/tools/menu99_mkgame.py` | A branch target that holds other bytes when the branch runs (code loaded over the caller's strings): the walk does not follow it |
| `# @piece` | `# @piece NAME` | `nether-earth-zs-edition/tools/game99_mkgame.py` | Starts one piece of a patches block. Each piece is a separate kit run over its own run range, placed inside `DISP` in the top file. The lines before the first piece hold for every piece |

Part-file generators describe an image of several segments in JSON instead of `case.json`.
`advanced-nether-earth/tools/endings_mkgame.py` / `disk_mkgame.py` and `nether-earth-zs-edition/tools/front99_mkgame.py`
take `--part src/<part>/<name>.json`:

```text
{"name", "image", "at", "out", "header", "l1": [...],
 "segments": [{"ann", "lo", "hi", "run", "bases", "read_builds", "title", "same_bytes", "data_entries", "load_label"},
              {"lo", "hi", "lines": [...]}],          a piece another part's source gives, its lines as they are
 "external": [...]}                                    @equ names the included sources define
```

- `run` is where the CPU runs the segment (`DISP` when it differs from `lo`).
- `same_bytes: true` counts a recorded instruction only when all its bytes are the image's (code later overwritten
  in the same window).
- `data_entries: true` makes every annotated data entry a stop for the walk.

`part_mkasm.py` / `trd_mkasm.py` take the part on the command line:

```bash
python3 tools/part_mkasm.py --image work/parts/loader-5d3b.bin --org '$5D3B' --ann src/loader/loader.ann \
    --top zynapsb --dest src/loader --res src/res --l1 work/stage2/loader/l1.json \
    --title 'Zynaps 2 in 1: ZYNAPS.B sector 0, the BASIC with the REM loader ($5D3B)' \
    --save build/obj/zynapsb-basic.bin --install
```

- Only whole basic blocks of the L1 build count, every instruction with the image's bytes. Another program that ran
  at the same addresses later in the recording cannot make a lone byte look like code.
- The `.ann`'s data entries stop the walk. The recording's data reads are not used.
- `--built NAME=PATH` keeps a resource the build makes (a text from its UTF-8 source) out of the install.
- `--page N` (zynaps-gs) restricts the code to one RAM page.

The case's script that runs every part in order is the one to call: `tools/mkasm_all.sh` (zynaps-128),
`tools/regen.sh` (zynaps-gs), `tools/game99_mkgame.py all` (nether-earth-zs-edition).

## 6. Starting and growing a `.ann`

1. **Empty first.** With `case.json` filled in (recipe 01) and at least one L1 build in `work/<build>/l1.json`
   (recipe 04), an `.ann` that holds only its header comment already works:
   `mkgame.py --case C ...` gives an image of `sub_` / `l_` / `data_` entries that assembles identically (Zynaps,
   WALKTHROUGH 4). Do not `--install` yet. Read `work/mkgame/game.ctl` and `work/mkgame/*.asm` for the cut the
   recordings give.
2. **The analysis as input.** The L1 routines (entries, callers, profile), L2 region kinds (graphics, text, tables)
   and the review queue (recipe 04) say what each region is. `re_session.py export --work W` writes
   `W/draft/draft.ctl`, `draft.skool`, `draft.map.txt`, `draft.fields.json` and the findings register. These are
   for reading; translate them into `.ann` lines by hand or with a small script in `work/`. No kit script converts
   a draft into an `.ann`.
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
| An inner name that is one letter `b`, `c`, `w`, `t` or `s` | read as a kind | longer names |
| A string after a `CALL` taken for code | odd instructions (`LD BC,$1704`) after the call | `@inline $ROUTINE` |
| An L1 build of the loader in `read_builds` | the game's code taken for data (the depacker read its packed input there) | only builds after the unpack in `read_builds` |
| A recording of another program in `work/*/l1.json` | stray entries or code in the image (`kit/mkgame.py` reads every `work/*/l1.json`) | keep such builds in a nested folder (`work/stage2/<window>/`) or use a part generator that takes `--l1` |
| A comment that reads well but no run checked it | a wrong statement in docs 11 / 12 (a "tune frequency", a "life lost") | name and describe only what a run confirms ([GUIDE](../GUIDE.md) 6) |
| Editing `src/game/*.asm` | the edit is lost at the next `--install` | edit the `.ann` |
