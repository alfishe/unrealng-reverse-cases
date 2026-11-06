# <Case>: stage 2 brief (the full own source, bit-exact)

R = the repository, C = R/games/<case>, B = R/games/<base> (the reference case). Stage 1 is done: read
C/work/stage1/NOTES.md, C/docs/02 and 03 first.

## The standard (binding)

- R/GUIDE.md section 1, R/recipes/05-source.md, 06-resources.md, R/docs/ann-format.md, R/kit/README.md.
- Every stage of the medium (BASIC, loaders, packed blocks, the game, every other part) is annotated source plus
  editable resources, built back bit for bit. An `.ann` per part, split into `@module`s; every routine named and
  described (what, inputs, outputs, side effects); every data entry named and shaped; operands as labels
  (`Label+offset` inside an entry); `@isub` for numbers that only look like addresses.
- The `.asm` is written by `R/kit/mkgame.py` (the game from `case.json`, every other part from a part file
  `src/<part>/<name>.json` or one `--image` line, ann-format.md section 5), never edited by hand. Write no generator
  of your own: a need the kit lacks goes to the lead as a note.
- A derived case: **never "the base's source + ORG patches"**. Where the bytes equal the base's you may seed from
  B's `.ann` text, but every description must be true for THIS game; "as in <base>" is not a description.
- Every statement has an address and a witness. Name a routine after checking it runs as you say (a breakpoint
  hit, an L1 count). What no recording reached is said to be known only from the code.

## Recordings

- The analysis builds: `python3 $RS build --work W --from-frame F --to-frame G --into C/work/<build>` over a window
  where only this part's code lies in memory. `case.json` `read_builds` / `code_builds` (or a part file's `l1`)
  names exactly the builds that count; never every `work/*/l1.json`. A build over a depacker's input counts its
  instructions only.
- `RS=$UNREAL_NG/tools/verification/analysis/re_session.py`; SkoolKit `$SKOOLKIT_VENV`; sjasmplus `$SJASMPLUS`.

## Layout

| Part | Source | Bytes it builds |
| --- | --- | --- |
| <part> | `src/<part>/<part>.ann` -> modules, `src/res/<part>/` | <image, range> |

`tools/build.sh` must print identical after every step; keep the old path working until its replacement is
bit-exact, then delete the raw image a module replaced. Resources in editable formats (PNG, UTF-8 text with the
build restoring the encoding, `.pt3` / `.stc`, text maps), a README per resource folder (address, size, format,
readers). Bytes no code reads are kept as documented leftovers, never silently.

## Rules

- Own instances on your port base, muted, stopped when done; never pids or ports not yours.
- Never edit B, R/kit or other cases. Case tools in C/tools/, temp files in C/work/stage2/.
- English in files, hex in code spans. No commits.

## Output

The `.ann` files, the generated `.asm`, the part files, `tools/build_<part>.sh`, `tools/build.sh` identical;
C/work/stage2/NOTES.md. Report: per part, entries and modules, what is known only from the code, open points.
