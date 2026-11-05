# The files of a case

Every file a case has: what makes it, what reads it, and whether git keeps it. Paths are relative to the case,
`games/<game>/` (`$C`). `$K` is `kit/`, `$U` the unreal-ng checkout, and `$RS` is
`$U/tools/verification/analysis/re_session.py`. The `.ann` format is in [ann-format.md](ann-format.md). The steps
that make these files are in [recipes/](../recipes/README.md).

The repository's `.gitignore` ignores `**/work/`, `**/build/`, `*.lst`, `*.sym`, `*.sld`, `*.exp`, `*.labels`,
`*.pk` and `features.ini` (the emulator's settings, written into the folder it runs in). Everything else in a case is
committed.

## 1. The case at a glance

| Path | Holds | Made by | Read by | Git |
| --- | --- | --- | --- | --- |
| `README.md` | the summary: the original and its hashes, the machine, the build command, the state, the document index | the lead (from `$K/case-template/README.md`) | readers; the repository README links it | yes |
| `WALKTHROUGH.md` | how the reverse was done: a section per question, the commands, the tool-gap table, the review rounds | everyone, written as the work goes | reviewers, the next case | yes |
| `case.json` | what the kit needs to know about the game image | the lead (template) | `mkgame.py`, `refdocs.py`, `sig_add.py`, `heatmap.py`, `fig_budget.py` | yes |
| `orig/` | the original distribution, unchanged | copied in once | the build's compare, the image tools, the captures | yes |
| `src/` | the sources and resources that build the medium | generators (`.asm`), people (`.ann`, layouts) | `tools/build.sh` | yes |
| `tools/` | the case's own scripts | the case's agents | the WALKTHROUGH commands | yes |
| `docs/` | documents 01-12 (13 for a derived case), figures, texts, audio | docs agents, `refdocs.py`, figure scripts | readers, `check_docs.py` | yes |
| `build/` | the build output | `tools/build.sh` | the compare, `sig_add.py` (the listings) | no |
| `work/` | recordings, analysis builds, traces, notes, briefs | `re_session.py`, MCP, the case tools, agents | everything that measures | no |
| `tests/inputs/` | input scripts worth keeping (nether-earth, zynaps): the runs a WALKTHROUGH command replays | the case's agents | `re_session.py capture --inputs`, the bots | yes |

## 2. `orig/`

The distribution exactly as found: a tape (`.tap`, `.tzx`, often inside a `.zip`), a disk (`.trd`, `.scl`), and any
text that came with it (`VORTEX.TXT`). The files are never edited, renamed or unpacked in place. A tool that needs
the bytes reads the zip itself (zynaps-gs `tools/build.sh` compares against `orig/ZYNAP_GS.ZIP`).

- Hashes: run `md5 orig/*` and `shasum orig/*`, and put the md5 and SHA-1 of every file in the case README's table.
- Listed by:
  - `python3 $K/tapblocks.py list orig/GAME.TAP` (a tape)
  - the case's `tzxblocks.py` / `tzx_blocks.py` (a TZX)
  - `tools/disk_files.py`, `tools/disk.py list`, or `tools/scl.py list` (a disk: the catalogue, each file's start,
    length and sectors, and the bytes past the stated length)

## 3. `case.json`

The keys are in the [kit README](../kit/README.md#a-case) table. Defaults (from `$K/case-template/case.json`):

```json
{"image_cmd": ["sh", "-c", "mkdir -p work/mkgame && python3 ../kit/tapblocks.py orig/GAME.TAP 3 work/mkgame/original.bin"],
 "image": "work/mkgame/original.bin", "lo": "6000", "hi": "10000", "device": "ZXSPECTRUM48",
 "bases": {"5": "4000", "2": "8000", "0": "C000"}, "read_builds": ["game"],
 "ref_builds": [["game", "the first recording's game window"]],
 "header": ["; GAME, PUBLISHER YEAR: the game image as the loader leaves it."]}
```

- `image` lives under `work/`, so `image_cmd` must be able to make it from `orig/` on a fresh clone. The cases do
  this with a script such as `tools/image.py` (zynaps) or `tools/game_image.py` (nether-earth-gs).
- `bases` maps L1 pages to the Z80 addresses that count. With the defaults, code that ran in another bank at
  `$C000` does not count. A 128K game's other banks are handled outside the kit (`# @bank`, part generators:
  [ann-format.md](ann-format.md#5-extensions-in-the-cases)).
- A case whose parts are not one 64 K image has part files instead: JSON next to each `.ann`
  (`src/endings/deadend.json`, `src/stage2/stage2.json`), `src/mix/case.json` (nether-earth-editor, which has no
  root `case.json`), or the configuration inside the part's `tools/<part>_mkgame.py`.

## 4. `src/`

| Path | Holds | Made by | Git |
| --- | --- | --- | --- |
| `src/game/game.ann` | the annotations of the game image | people (the annotators, the lead's merge) | yes |
| `src/game/*.asm`, `game.asm` | one file per module, plus the top file | `$K/mkgame.py --install` (or the case's wrapper); **never edited** | yes |
| `src/<part>/<part>.ann` + `.asm` | the other code images: loader, depacker, boot, menu, intro, sound engine, GS driver | `tools/part_mkasm.py`, `trd_mkasm.py`, `<part>_mkgame.py` ([ann-format.md](ann-format.md#5-extensions-in-the-cases)) | yes |
| `src/<part>/<name>.json` | a part's segments (image, run addresses, banks, L1 windows) | people | yes |
| `src/loader.asm`, `src/basic.asm`, `src/tape/*.asm` | the small stages written by hand from the blocks (BASIC, a loader in a REM, a header) | people | yes |
| `src/res/` | every resource in its editable format (PNG, `.scr`, text) plus `README.md` listing each file: address, size, format, readers, preview | `mkgame.py --install` through `tools/res_formats.py install`, the case's `*_res.py` | yes |
| `src/res/text/` | the texts as build input (a codec's text: `#codec cp866`, `\xNN` escapes) | `tools/trd_text.py`, `texts_build.py`, `res_text.py` | yes |
| `src/media/*.txt`, `src/disk*.txt` | the medium's layout: the TRD / SCL catalogue (label, entries, sectors), the TAP / TZX block list with pauses and archive info | people, from the listing of `orig/` | yes |
| `src/**/*.hints`, `src/sfx/hints/*.lzhints` | packer hints: the original packer's token choices that the greedy rule does not reproduce (`POS KIND LEN OFF RULE...`) | the packer's `check` mode (`tools/zspack.py`, `tools/hrust1.py`) | yes |

The build needs only the `.asm`, the resources and the layouts. The `.ann` files and the generators are needed only
to regenerate the `.asm`.

## 5. `tools/`

The case's own scripts. What every case shares is in `$K`. A tool taken from a sibling case is **copied** and its
header names where it came from: the cases stay apart and never import each other's tools.

| Script | Does | Seen in |
| --- | --- | --- |
| `build.sh [SJASMPLUS]` | builds the whole medium from `src/` and compares it with `orig/` (`build: identical to orig/...`); holds `build/.lock` | every case |
| `build_<part>.sh` | one part (game, loaders, intro, sound, texts) into `build/<part>/` | ANE, ZS, GS |
| `res_formats.py` | `install(files)` for mkgame; `check` (round trip), `export`, `build --out build/res` | every case |
| `depack.py` / `pack.py`, `hrust1.py`, `hrum.py`, `zspack.py`, `picy.py`, `trush.py`, `ultraxor.py`, `xorchain.py` | each packer or cipher both ways, with `check` against the medium | per packer |
| `image.py`, `game_image.py`, `parts.py` | cut the images the generators read out of `orig/` (into `work/`) | zynaps, GS, zynaps-128 |
| `*_mkgame.py`, `part_mkasm.py`, `trd_mkasm.py`, `mkasm_all.sh`, `regen.sh` | regenerate the `.asm` from the `.ann` files | derived cases |
| `mkscl.py`, `mktrd.py`, `mkdisk.py`, `mktap.py`, `tzx.py` (and `$K/tap.py`) | write the medium from `src/media` | per medium |
| `bot.py`, `autopilot.py`, `play_bot.py`, `play_live.py`, `drive.py`, `gs_session.py` | play the game over WebAPI / MCP and record it | per case |
| `verify_*.py`, `check_load.py` | a resource or a load checked against a recording | hate, zynaps |
| `fig_*.py`, `res_preview.py`, `render_audio.py` | figures, data sheets, audio | every case |
| `diff_*.py`, `byte_diff.py`, `ne_match.py`, `entry_diff.py`, `fig_compare.py`, `fig_diff_*.py` | a derived case against its base ([recipe 10](../recipes/10-derived-case.md)) | derived cases |

## 6. `build/`

Not in git. Made only by `tools/build.sh`, which is run by one builder per case at a time.

| Path | Holds | Read by |
| --- | --- | --- |
| `build/.lock` | a directory taken with `mkdir`, removed by a `trap` on exit. A second build waits (zynaps, ZS: a lock older than 30 minutes is taken over) or fails at once (zynaps-128, the GS cases). `build_trd_extras.sh` uses `build/.lock-trd` | the next build |
| `build/*.lst`, `build/lst/*.lst`, `*.sym` | the sjasmplus listings (`--lst`) | `$K/routine_anim.py` / `writers_map.py` / `beam_timeline.py` (`--listing`), `$K/sig_add.py` (`--lst`, `sources.json`), the diff tools |
| `build/game.bin`, `build/obj/*.bin`, `build/<part>/` | the assembled images | the packers, the diff tools (`../<base>/build/game.bin`) |
| `build/res/` | resources built from their editable sources | the `INCBIN`s |
| the medium (`build/GAME.TAP`, `build/ZYNAP_GS.TRD`) | the rebuilt original | the compare |

Because the listings are build output, `$K/sig_add.py sources` and every diff tool need the cases (and the base
case) built first.

## 7. `work/`

Not in git, and tens of megabytes per recording. Every file here is made again by a command in the WALKTHROUGH. The
names follow the case: a recording's folder is named after the run (`c1`, `p2`, `r1`, `deep`), and a stage's
or agent's folder after the stage or agent (`stage1/`, `stage2/<part>/`, `zyA/`, `docs/`).

### 7.1 A `re_session.py` work folder

`python3 $RS capture --work W ...` (or `open --work W --ttd T`) makes these:

| File | Is | Consumer |
| --- | --- | --- |
| `session.json` | the live instance: `pid`, `binary`, `port_base`, `model`, `ranges` | every later `re_session.py` call, the kit's `--work` scripts, `stop` (it checks the pid is still that unreal-qt) |
| `capture.json` | the capture's parameters | the WALKTHROUGH |
| `session.ttd` | **the recording** (TTD), saved once and opened again for every question | `re_session.py open --ttd` |
| `power-on.szx`, `start.szx`, `start.bin` | the machine at power-on, the start state, and the memory at the first keyframe (or at the window's start after a `build`) | the image tools, the rebuild gate |
| `l1.json` | the L1 build: `replay` (frames, T-states), `pages`, `routines` (entry, page, profile), `blocks`, `calls`, `loops`, `dataflow`, `branches`, `instructions`, `arrivals`, `byte_use`, `byte_counts` | `mkgame.py` (every `work/*/l1.json`), `refdocs.py` (`ref_builds`), `heatmap.py`, `fig_budget.py`, `re_session.py stages` / `interrupts` |
| `review.txt`, `findings.txt` | the review queue's first page and the findings counts | the analysis (recipe 04) |
| `screens.png`, `screens/`, `snapshots/` | eight screens through the run, and snapshots every N frames | a first look; starting points for experiments |
| `draft/` | `re_session.py export`: `draft.skool`, `.ctl`, `.map.txt`, `.fields.json`, `.geometry.json`, `.symbols`, `findings.md`, `findings.jsonl` | input to the first `.ann`; `re_session.py check` |
| `check.json` | the `rebuild` / `assemble` gates | recipe 04 |
| `traces/F_T-F_T.uatr` | access traces (unreal-ng `analysis trace`), made once per window by the kit's trace scripts and read from here afterwards | `routine_anim.py`, `writers_map.py`, `beam_timeline.py` |

`python3 $RS build --work W --from-frame F [--from-tinframe T] [--to-frame G] --into W/<stage>` writes `l1.json`,
`start.bin`, `review.txt`, `findings.txt` and a `session.json` that points to W's instance. The stage folder shares
the instance but does not own it, so stop the instance through W.

The L1 builds `mkgame.py` must **not** read (another program's code at the same addresses, a loader window) are kept
one level deeper (`work/stage2/<window>/l1.json`), because the kit globs only `work/*/l1.json`. A part generator
takes them with `--l1`. To give the kit a deeper build, link it: `ln -s ../stage2/game/l1.json work/c1/l1.json`
(zynaps-128).

### 7.2 The rest of `work/`

| Path (examples) | Is | Made by |
| --- | --- | --- |
| `work/mkgame/` | the generator's work: `original.bin`, `game.ctl`, `game.skool`, `*.asm`, `game.bin` | `mkgame.py` (`refdocs.py` reads `game.ctl`) |
| `work/stage2/mkasm/<top>/`, `work/stage2/<part>/mk*/` | the same per part | the part generators |
| `work/media/`, `work/parts/`, `work/images/` | files cut out of `orig/`, per-bank dumps (`ttd_dump.py --pages 0-7`) | `disk_files.py`, `parts.py`, `ttd_dump.py` |
| `work/<run>/inputs/*.txt` | input scripts (mm_session / zx-reaper format: frame, key, hold; end with `N END`) | people, bots |
| `work/<bot-run>/*.tsv`, `*.log` | a bot's log: frame, level, lives, score | `bot.py`, `play_bot.py`, `autopilot.py` |
| `work/<run>/*.scr`, `shots/` | screens from `memory_at` at named frames | `compare_shots.py`, `fig_capture.py`, `$K/screen_shot.py` |
| digests (`gs_digest.py`), `hist:` captures, `port_events` dumps | device histories (the GS ports, the bus) | the case's session tools |
| `work/audio/` | WAV renders before conversion | `render_audio.py`, `sound_render.py` |
| `work/diff/` | `diff.json`, `entries*.tsv`, `code.md`, `res.json`, `bytes.json` | the diff tools (recipe 10) |
| `work/BRIEF.md`, `work/stage*/BRIEF*.md`, `work/docs/BRIEF.md` | the lead's briefs | the agents ([recipe 11](../recipes/11-agents.md)) |
| `work/stage*/NOTES*.md`, `STATE-<part>.md`, `work/docs/<id>-NOTES.md`, `<id>-index.md`, `<id>-diff-notes.md` | each agent's commands and what each proved; index and glossary lines for the lead | the lead's merge, the WALKTHROUGH |
| `work/ann/NN-*.ann`, `NN-xref.txt`, `NN-notes.md` | annotation fragments | the lead's merge into `game.ann` |
| `work/lead/` | the lead's fix scripts (`fix_ann.py`, `fix_docs.py`) with the files as they were before | the editor pass |

A finding that lives only in `work/` does not count. It goes into the WALKTHROUGH or a document in the same step.

## 8. `docs/`

| Path | Holds | Made by |
| --- | --- | --- |
| `docs/README.md` | the index of the documents and their state, the recordings table (name, how loaded, frames), the glossary (every term defined once) | the lead / editor, from the agents' `<id>-index.md` |
| `docs/01-...md` - `10-...md` | the subsystems ([GUIDE](../GUIDE.md) 3) | the docs agents |
| `docs/11-data-reference.md`, `12-routine-reference.md` | generated | `python3 $K/refdocs.py --case $C` (or the case's `refdocs_zy.py`, `zsB_refdocs.py`, `fig_refdocs.py`) |
| `docs/13-differences-from-<base>.md` | a derived case only, written last | the lead, from the diff tools (recipe 10) |
| `docs/img/<topic>/` | the figures by subject (`arch`, `load`, `loop`, `render`, `objects`, `hud`, `sound`, `controls`, `design`, `play`, `routines`); `docs/img/routines/<Label>.gif` is linked from doc 12 | the kit's and the case's figure scripts, each named in the WALKTHROUGH or the caption |
| `docs/img/res/` | resource previews | `tools/res_preview.py` |
| `docs/img/compare/` | start-up and menu screenshots side by side with the base | `tools/fig_compare.py` (recipe 10) |
| `docs/img/diff/` | the doc-13 figures | `tools/fig_diff_*.py` |
| `docs/texts/` | each disk / tape text as UTF-8 Markdown: what it is, file and address, encoding, the build input it comes from, the original, the translation | the case's text tool (`trd_text.py`, `texts_build.py`, `game_text.py --markdown`) plus the translator |
| `docs/audio/` | MP3 renders of the tunes and effects, plus `README.md` (the table) | `tools/render_audio.py` (it rewrites the README too) |

`python3 $K/check_docs.py --case $C` must print `docs: ok`. It checks that mermaid renders (`mmdc`), that links and
images resolve, that no `$` is left in prose, and lists figures in `docs/img` and `docs/img/routines` that no
document links. It does not look into the subfolders of `docs/img` other than `routines`.

## 9. `signatures/sources.json`

One row per addition to the signature base, replayed in order by `python3 $K/sig_add.py sources`:

```json
{"mode": "ann", "case": "games/nether-earth", "program": "Nether Earth", "authors": "Argus Press Software",
 "year": 1987, "lst": "build/game.lst"}
{"mode": "lst", "case": "games/zynaps-gs", "program": "Zynaps GS: the patch installer", "lst": "build/lst/install.lst",
 "start": "Install", "end": "Mover", "id": "programs/games/zynaps-gs/installer", "meta": {"role": "game-module", ...}}
```

- An `ann` row gives one entry per module of the case's `.ann`. It can also take `ann`, `config` (for a part with
  its own `case.json`), `family`, `bank` and `modules`.
- An `lst` row gives one entry from a listing between two labels, with its metadata. Use it for the third-party
  pieces the case identified (players, depackers, drivers).
- After editing: `python3 $K/sig_index.py --check`, then `python3 $K/sig_index.py` (writes `index.json` and
  `INDEX.md`).

The rows are added when a case is finished ([recipe 10](../recipes/10-derived-case.md) for the order in a derived
case). The format is in [signature-format.md](signature-format.md).

## 10. The unreal-ng side

| What | Where |
| --- | --- |
| The checkout | the `unreal-ng/` submodule, `$UNREAL_NG`, `--unreal`, or a checkout next to this repository (the kit looks in that order). The cases ran from one worktree of the owner's checkout, `scratch/wt-<name>`, set as `UNREAL_NG` |
| The binary | `$U/cmake-build-agent-release/bin/unreal-qt.app/Contents/MacOS/unreal-qt` (`corpus.DEFAULT_BINARY`; give another with `--binary`). It is built in the unreal-ng worktree with `tools/build/build.sh unreal-qt` |
| `re_session.py` | `$U/tools/verification/analysis/re_session.py`: `capture`, `open`, `build`, `stages`, `interrupts`, `call`, `export`, `check`, `stop` (its docstring is the reference). Beside it: `mm_session.py` (input scripts), `corpus.py` (the launcher and MCP client), `access_trace.py` (the trace reader the kit uses), `score_draft.py` |
| The analysis layers | `$U/docs/emulator/analysis/analysis-layers.md`: L0 access facts, L1 routines and value flow, L2 region kinds, L3 findings, the access trace |
| Recipes | `$U/.recipe/articles/game-reverse-case.md` (MCP for a case, without waste), `$U/.recipe/articles/game-reverse-pipeline.md`, `$U/.recipe/analysis/reverse-engineering.md`, `ttd-recording.md`, `ttd-write-journal.md`, `ttd-gameplay-automation.md`, `game-start-input.md`, `nonstandard-loader.md`, `port-trace.md` |
| WebAPI | `$U/.recipe/testing/webapi-verification.md`; models: `GET /api/v1/emulator/models` |

**The shared-binary rule.** Every agent of a case runs the **same** release binary, read-only. Each agent gets its
own port base and its own instances, and stops only those. No agent builds unreal-ng or makes a worktree for itself
(the docs briefs: "never build unreal-ng or create a worktree", the disk was full). A tool gap found during a case is
fixed by one agent in one unreal-ng worktree, landed, and the shared binary rebuilt once. The analysis builds are
then made again with it. A `session.json` names the binary it ran, so a recording can be traced to the build that
made it.
