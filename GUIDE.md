# Reversing a game: the case standard

What a finished case in this repository is, and how to get there with unreal-ng. The steps are in
[recipes/](recipes/README.md); the shared scripts are in [kit/](kit/README.md); how to drive the emulator over MCP
without wasting time or tokens is unreal-ng's
[game-reverse-case recipe](https://github.com/alfishe/unreal-ng/blob/master/.recipe/articles/game-reverse-case.md).
[H.A.T.E.](games/hate/README.md) is the first case and the worked example; what it lacked is said below, and a new case
does better there.

## 1. The deliverable

| Part | Requirement | Checked by |
| --- | --- | --- |
| `orig/` | the original distribution, unchanged, with its md5 / SHA-1 in the README | `sha1sum` |
| `src/` | sjasmplus sources of every stage on the medium (BASIC, loaders, packed blocks, the game), every routine named and described, operands as labels (`Label+offset` inside an entry), constants that only look like addresses written as constants | `tools/build.sh` |
| `src/res/` | every resource out of the code: graphics, fonts, screens, maps, levels, music, texts, tables. Each in an editable format (PNG for graphics, text for tunes and levels) that the build turns back into the original bytes for `INCBIN`; a README lists each file with its format | `res_formats.py check`, the build |
| the build | `tools/build.sh` makes the original medium **bit for bit** from `src/` (the packers are reimplemented, both ways) | the build's own compare against `orig/` |
| `docs/` | the game's documents as a team writing it today would keep them: design, architecture, build and load, every subsystem, data and routine references (section 3) | `kit/check_docs.py`, the review rounds |
| figures | rendered from the recordings by scripts in `tools/` or `kit/`, every one reproducible, of the kinds and density in section 4 | the figure checklist |
| `WALKTHROUGH.md` | how the reverse was done: each step's question, the emulator capability that answered it, the command, the result; the tool gaps found and how unreal-ng was fixed | read by a reviewer who did not do the case |
| `work/` | recordings and analysis builds, local only (git-ignored); every one rebuilt by a WALKTHROUGH command | |

The source is generated, not typed: one annotation file (`src/game/game.ann`: module, entry kind, name,
description, comments, data shapes, `@isub`, `@res`) is the single source of truth, `kit/mkgame.py` writes the
`.asm` from it, the image and the recordings, and installs it only when sjasmplus gives the original bytes. Edit
the annotation, never the generated `.asm`.

## 2. Evidence

- **Every statement has an address and a witness.** An address in `src/`, and what the emulator saw: a recording
  and frame, a counter, an L1 build, an experiment on a clone. "Not executed in this recording", never "dead code".
- **Numbers come from scripts.** Frames, T-states, counts, sizes are printed by a script over a recording or the
  listing, and the same number is written the same everywhere. When a number is re-measured, every document that
  states it changes in the same commit (H.A.T.E.'s last rounds were given three different ways in three documents).
- **Hardware and format claims are checked**: against the ROM, the tape bytes, the listing, a second recording;
  a comment or an earlier document is not evidence.
- **Everything the analysis cannot name is a tool gap.** Fix it in unreal-ng with a generic rule, a fixture and a
  test (never a rule tuned to this game), rebuild, and note the gap in the WALKTHROUGH's tool-gap table.
- **Reach the content.** Random play and the demo reach the first screens. A bot that reads the game's own records
  (H.A.T.E.'s `autopilot.py`) or input scripts per part of the game reach the rest; what no recording reached is
  listed as known only from the code.

## 3. The documents

The numbering is fixed so that cases read alike; a subsystem the game lacks keeps its number with one line.

| Doc | Contents |
| --- | --- |
| `01-game-design.md` | the game as a player meets it: premise, controls, objects, rules, scoring, modes, difficulty |
| `02-architecture.md` | the machine budget, the memory map (a figure), stages from the medium to play, the frame, the main loop's call graph, the module map |
| `03-build-and-load.md` | the medium block by block, loaders, packers and their formats, the unpack animations, the source build |
| `04-game-loop.md` | the state machine (a diagram), the frame schedule, the order of work inside a pass, timing |
| `05-controls.md` | devices, ports, decoding, menus, hidden keys |
| `06-rendering.md` | the screen and how it is drawn: buffers, blits, scrolls, sprites, the raster timing |
| `07-objects.md` | records, slots, kinds, movers, collisions |
| `08-hud-and-text.md` | panels, fonts, the print routine, every string |
| `09-sound.md` | the engines, music and effects formats, the players, timing |
| `10-gameplay-logic.md` | the rules as code: the player, enemies and their behaviour, levels, scoring, what the recordings showed |
| `11-data-reference.md` | every data entry: address, format, readers and writers (generated, `kit/refdocs.py`) |
| `12-routine-reference.md` | every routine: purpose, runs, time, callers, callees, memory, ports, **its figures** (generated) |

Writing rules:

- Hex addresses in prose are code spans (GitHub reads a pair of `$` as math; `kit/check_docs.py` fails on it).
- Mermaid diagrams are rendered by `check_docs.py`; GitHub's renderer is stricter than most.
- A term is defined once, in `docs/README.md`, and linked; the WALKTHROUGH's intro points there.
- Each document opens with what it covers and which recordings it rests on.

## 4. Figures

H.A.T.E. was criticised for too few figures: the memory heatmaps were mostly static, and the link between a
routine's code and what appears on the screen was told in words. A new case meets this standard.

### 4.1 Kinds

| Kind | What it shows | Tool |
| --- | --- | --- |
| **Routine animation** | one call of a routine, instruction by instruction (sampled): the memory map with executed, read and written bytes lit by age; the listing window with the current instruction and the registers; the screen or the buffer it draws into, the written bytes lit; the frame, the T-state and the beam position | `kit/routine_anim.py` (the CPU access trace) |
| **Code vs screen** | which instruction drew which pixel: the screen with every byte coloured by the routine (and, zoomed, the instruction) that wrote it last in the frame; source bytes (a sprite, a tile, a glyph) tied to where they land | `kit/writers_map.py` |
| **Beam timeline** | a frame as time: routines along the T axis, the raster line at each moment, the screen writes against the beam (where tearing would show, why the game draws in this order) | `kit/beam_timeline.py` |
| **Stage animation** | memory over a stretch: a load, an unpack, a level set-up, a scroll step | `kit/memanim.py` |
| **Heatmap** | executed / read / written per byte over a whole build, shaped like the data (a buffer as its geometry, the screen as the screen) | `kit/heatmap.py` |
| **Data sheet** | a format drawn from its bytes: a sprite sheet with masks and frames, a tile set, a map, a font, with the byte grid and offsets | `tools/res_preview.py` per case |
| **Diagram** | state machines, call graphs, data flow (mermaid) | by hand, rendered by `check_docs.py` |
| **Screenshots** | each screen and mode the game has, at named frames | `kit/screen_shot.py` |

### 4.2 Density

- `02`: the memory map as a picture (stages side by side), the module heatmap, the frame budget.
- `03`: an animation per loader and per unpacker; the medium as a picture (blocks, times).
- `04`: the state machine; a beam timeline of a typical pass and of the heaviest one.
- `06`-`10`: at least one routine animation for each subsystem's central routine (the blit, the scroll, the
  sprite drawer, the mover, the collision test, the sound player), and a code-vs-screen figure for everything that
  draws. A figure says what the text would need a page for: write the caption first, then the figure, then cut
  the text it replaces.
- `12`: every routine that takes more than 1 % of the time or draws to the screen links its animation; the
  others link the heatmap row that holds them.

### 4.3 Rules

- Rendered from a recording by a script in `tools/` or `kit/`; the caption names the recording, frames and
  T-states, and the WALKTHROUGH names the command. Never a hand-edited picture.
- Animations: GIF (or APNG), at most about 4 MB, 2x scale, a frame/T counter in each picture, a pause on the first
  and last picture. Sample by instructions or T-states so the motion is readable (20-150 pictures).
- One palette across the case: executed, read and written each have one hue; the age fades it.
- A figure shows the screen with the colours the game used (ink, paper, bright, flash phase named).

## 5. Process

| Phase | Done when | Recipe |
| --- | --- | --- |
| 0. Start the case | `orig/` with hashes, the medium listed block by block, the case README | [01](recipes/01-start-a-case.md) |
| 1. Capture | a recording from power-on with the load; a start image; recordings that reach every part of the game | [02](recipes/02-capture.md) |
| 2. Stages and packers | every stage named with its window; each packer reimplemented both ways and proved against the recording | [03](recipes/03-stages-and-packers.md) |
| 3. Analysis | L1 / L2 builds per stage; the review queue worked down; no unknown left outside the ROM (or each one explained) | [04](recipes/04-analysis.md) |
| 4. Source | `game.ann` complete; the medium rebuilt bit for bit from `src/` | [05](recipes/05-source.md) |
| 5. Resources | every resource in `src/res` in an editable format, checked against the recording | [06](recipes/06-resources.md) |
| 6. Figures | the section 4 checklist met | [07](recipes/07-figures.md) |
| 7. Documents | docs 01-12 written, generated references current, `check_docs.py` ok | [08](recipes/08-documents.md) |
| 8. Review | at least two independent review rounds with every finding checked; a WALKTHROUGH section per round | [09](recipes/09-review.md) |

Write as you go: the WALKTHROUGH and the documents are updated after each finding, not at the end. A finding that
lives only in a chat, a note or `work/` does not count. In the case repository, commit after each finished phase.

## 6. Lessons from H.A.T.E.

| Lesson | Now |
| --- | --- |
| Few figures; code and screen linked only in words | section 4 is a requirement, checked in review |
| The same frames given differently in three documents | numbers from scripts; one commit changes them everywhere |
| Fast tape load shifts every frame number of a recording | say which recording and how it was loaded next to every frame number |
| A depacker reading where code later lies spoils the data reads of the load | build the analysis per stage window; take data reads from the windows after the unpack |
| One blitter filled L1's copy list and starved the rest | tool gaps fixed generically in unreal-ng (a cap per copier), with a test |
| Random play reached two rounds | a bot from the game's own records; a list of what no recording reached |
| Reviews found errors after the documents looked done (31 in the fourth round) | review rounds by fresh agents, each finding verified against code, tape or recording before a fix |
| `$` pairs rendered as math on GitHub | addresses in code spans, enforced |
