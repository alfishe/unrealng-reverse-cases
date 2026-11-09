# Agent rules: reversing a game to the case standard

This file is for every agent working in this repository, whether lead, stage agent, docs writer or reviewer. It
says how a reverse is done, and it sets the bar a case must meet before anyone calls it done. Detail is elsewhere:
the standard in [GUIDE.md](GUIDE.md), the steps phase by phase in [recipes/](recipes/README.md), the scripts in
[kit/](kit/README.md). Where this file is stricter than those, this file wins.

> **Why this file exists.** On 2026-11-08 the owner rejected Exolon's documents as incomplete and sloppy. Doc 03
> described the decryption without a single diagram, explained the loader and the picture unpacker only by "as in
> Zynaps", and four subsystem documents had no diagram at all. A fact review had passed them. Facts being true is
> not enough: a document is done when it **explains** every mechanism it owns, completely, on its own.
>
> **And on 2026-11-09** Moon Patrol's documents stayed empty stubs for hours while the capture and the source were
> done, then came back as 2 700 lines with no picture, dangling image links and a sprite drawn in `#` and `.`, and
> with no animation at all. The rules in section 7 (the order of work) and section 4.0 (the game's profile) come from
> that.

## 1. The method in one page

| Phase | What you do | Done when | Recipe |
| --- | --- | --- | --- |
| 0. Start | Put the original in `orig/` with its hashes. List the medium block by block. Write the case README. Pick the game's profile (section 4.0). | every block named, with its size, address and time; the profile in the README | [01](recipes/01-start-a-case.md) |
| 1. Capture | Record from power-on with the load. Take a start image. Make recordings that reach every part of the game: a bot, input scripts, warp clones. | every zone, level and mode reached by a recording, or listed as reached only from the code | [02](recipes/02-capture.md) |
| 2. Stages and packers | Name every code arrival with its window. Reimplement every packer and cipher in both directions. | each stage proved against the recording byte for byte | [03](recipes/03-stages-and-packers.md) |
| 3. Analysis | Build L1 / L2 per stage window. Work down the review queue. | no unknown left outside the ROM, or each one explained | [04](recipes/04-analysis.md) |
| 4. Source | Write `game.ann` and generate the `.asm` from it with `kit/mkgame.py`. | `tools/build.sh` prints identical | [05](recipes/05-source.md) |
| 5. Resources | Extract every graphic, font, map, level, tune, text and table into an editable format that builds back. | `res_formats.py check` passes and the build is identical | [06](recipes/06-resources.md) |
| 6-7. Documents with their figures | Write docs 01-10 by hand, each section with its diagram, figure and animation in the same step; docs 11-12 are generated. Starts the moment the source is identical. | `check_docs.py` prints docs: ok, the animation minimum (section 4) and the profile items (section 4.0) are met, **and** the completeness audit (section 5) finds no P1 or P2 | [07](recipes/07-figures.md), [08](recipes/08-documents.md) |
| 8. Review | Run two rounds by fresh agents: facts plus completeness, then both again with the halves swapped. | round 2's findings fixed and committed | [09](recipes/09-review.md) |

Write as you go: a finding counts only when it is in the documents or the WALKTHROUGH. A finding left in a chat or
in `work/` does not count.

## 2. Evidence (non-negotiable)

- **Every statement has an address and a witness.** The witness is one of:
  - a recording, named, with the frame and how it was loaded;
  - a counter;
  - an L1 build;
  - a trace;
  - an experiment on a clone.

  If there is no witness, write "known only from the code" and say where the code shows it.
- **Numbers come from scripts.** A number is written the same everywhere it appears. When it is re-measured, every
  document that states it changes in the same commit.
- **Names and mechanisms are checked by a run before they go into a description.** Stage comments read well and
  are often wrong: in Zynaps the "engine hum" was the explosion noise, and the "life lost" effect was the laser.
- **A frame is not a pass.** A frame is 1/50 s of the machine; a pass is one turn of the main loop. Measure which
  one you mean, and define both in the glossary.
- **A number derived from a measure carries the measure.** Say the window it was measured over and what it includes
  (Moon Patrol: 8.4 frames a pass was the whole recording with the bonus screens; play alone is 7.05). Every number
  computed from it is recomputed when the measure changes.
- **A number the screen shows is checked against the screenshot.** Moon Patrol's first bonus was derived as 24 s;
  the bonus screen of the same recording says 98 s of 120, so 22 s.
- **Names are checked against the picture, not only the code.** A routine, its buffer, its counter and the data it
  reads must agree with each other and with what is on the screen (Moon Patrol: ScrollMountains scrolled the strip
  labelled HillsStrip; renamed by screen band).
- **Never "dead code".** Write "not executed in any recording", and say which recordings were checked.
- **Hardware claims** are checked against the ROM, the schematic or a second emulator. Never against a comment or
  an older document.
- **Never "same as <other case>" as the explanation.** A comparison may follow a full explanation; it never
  replaces one.

## 3. The mechanism bar: what "explained" means

Every mechanism a document owns must have all of the following, unless the item does not apply and the document
says why:

| # | Element | What it is | Example of the failure |
| --- | --- | --- | --- |
| 1 | **Prose that stands alone** | what it does, why the authors did it this way, its inputs and outputs | "The loader is Zynaps' Countdown II" with nothing after it |
| 2 | **Pseudocode** | named variables, real loops, no registers unless the register is the point | the asm only |
| 3 | **The asm** | the real listing, cut to the lines that make the point, addresses visible, a short comment column | an ad hoc `HL += DE` mix |
| 4 | **A mermaid diagram** | required for any branching, any loop with exits, any state machine, any sequence of stages, any data flow between three or more parties | a decrypt loop or a loader with no diagram |
| 5 | **A worked example** | real bytes or values from the image or a recording, stepped through: input, key or state, output | "it XORs each byte with the next" without three bytes shown |
| 6 | **A witness** | the recording and frame where it was seen, or "known only from the code" | "the countdown ticks per byte" with no frame |
| 7 | **A figure or animation** | wherever something changes in time or space: a routine animation, code vs screen, a beam timeline, a stage animation, a data sheet. Pixels are always a picture; flows are always mermaid | a sprite format given as a table with no drawn sprite; a sprite drawn in `#` and `.`; a link to an image not yet drawn |
| 8 | **The point** | one or two sentences on what the reader should take away, after every figure and every table | a table with no explanation |

A transform (a cipher, a checksum, a packer or unpacker, a compressor) always gets the full set: the format drawn
byte by byte, the pseudocode of both directions, a worked example on the real stream, a flowchart, and the
animation of the real run.

## 4. What each document must cover (the subsystem checklist)

The numbering is fixed; a subsystem the game lacks keeps its number, with one line saying so and the evidence. The
lists below are minimums. Each item is a mechanism under section 3.

**Animations are a minimum, not a decoration.** Each animation is a GIF drawn by `kit/routine_anim.py` (or
`kit/writers_map.py`) from a real trace of a recording, stored as `docs/img/routines/<Label>.gif` so doc 12 links it,
embedded in the section that explains the routine, with the recording, frames and command in its caption. At least:

| Document | Animations |
| --- | --- |
| 03 | every unpacker and decryptor at work (or one line: there is none) |
| 04 | the interrupt handler or the heaviest pass; any screen that holds the loop (bonus, level end) |
| 05 | the input path into the hero, or the name entry |
| 06 | every draw path: the hero, sprites, each scroller or the screen build, effects |
| 07 | the spawner and at least two object kinds at work |
| 08 | the print routine and the score update |
| 10 | the hero's movement (jump, fall, climb) and the death |

A case with fewer than ten animations is not done. One dropped after two unreadable tries is named in the
WALKTHROUGH with the reason.

**The figure minimum.** Besides the animations, every case has at least these, each drawn by a script from the image
or a recording and viewed by the lead at 900 px:

| Figure | What it shows | Document |
| --- | --- | --- |
| Screenshots | every screen and mode, and every key moment of section 01, at named frames | 01, WALKTHROUGH 6.1 |
| The memory heatmap | every byte of the address space coloured by executed, read, written, from L1 of all recordings | 02 |
| The module heatmap and the frame budget | where the CPU time goes, per module and per pass | 02, 04 |
| The sprite sheets | every sprite, frame, font and tile of the image drawn as a sheet, each labelled with its address, size and the routine that draws it; pre-shifted copies and masks shown | 06, `src/res` |
| The map | every level, room, course or table rendered from the image's data (section 4.0 says what "map" means for the genre) | 01, `src/res/maps` |
| Code vs screen | which routine wrote which pixels of a real frame | 06 |
| The beam timeline | a typical pass and the heaviest pass against the raster | 04 |
| The state machines | the program, the hero, each object kind (mermaid) | 04, 07, 10 |
| Data sheets | every record, table and format byte by byte | 07, 08, 09 |

**The notable features.** Each case ends doc 10 with a section on what is special in this game's code: the tricks
worth learning (a fast multiply, a clever erase, self-modifying code, a table that replaces a computation, a timing
trick), the bugs and oddities, and what the authors left (build dates, names, unused graphics and texts). Each item
with the asm, a witness and, where it shows on screen, a figure. A reader of the case should find at once what makes
this game different from the others in the repository.

### 4.0 The game's profile: genre, rendering, engine

The document lists below (01-10) are the same for every game. What a reader needs on top depends on the kind of game. In phase 0
the lead picks every profile row that applies (a game often has several: Moon Patrol is a scrolling arcade game with
a beeper tune in the interrupt), writes them in the case README, and puts their items into the writers' briefs. The
completeness audit checks them like the rest of section 4. A row not in this table is added here by the case that
meets it first.

**By genre: what the reader expects to find**

| Genre | Must have | Where |
| --- | --- | --- |
| Arcade, platform, flip-screen | the full map of every level or room rendered from the image's data, the room graph, every item and enemy placed on it, the route through it | 01, 07, `src/res/maps` |
| Scrolling arcade or shooter | each course or level drawn as a strip from its script (segments, what spawns where), the attack waves on a timeline, each enemy's pattern drawn as a path, the boss patterns | 01, 07, 10 |
| Racing, driving | every track drawn as a map with curves, slopes and hazards; the speed and steering model with its numbers; the expected techniques (braking points, racing line, shortcuts, tricks the code allows) with a recording of each; the opponents' AI | 01, 07, 10 |
| Maze, puzzle | every level rendered, the level format with a byte-to-picture example, a solution for each level checked by a recording, the rules of every tile | 01, 06, 10 |
| Adventure, RPG | the world map, the room and object graph, the parser's vocabulary and grammar, every script or event, the full walkthrough proved by an input script, every text with translation where not English | 01, 07, 08, 10 |
| Strategy, simulation | the model as equations with its tables (economy, growth, combat), the AI's decision rules, charts of the model over a played game, the balance a player can exploit | 07, 10 |
| 3D (vector, filled, voxel) | the projection math worked through on one object, the clipping, the line or polygon fill, every model drawn from its data, the camera, the frame rate against scene load | 06, 07 |
| Sports, fighting | the rules as code, the physics of the ball or the bodies, the move list with frames and hit boxes, the AI players | 07, 10 |
| Physics simulation (billiards, pinball, ball games) | the number formats (fixed point, tables), the motion and friction model, the collision detection and response worked through on one real shot, the trajectory drawn from a recording against the model, the aiming aids and the AI's shot choice | 07, 10 |

**By rendering**

| Rendering | Must have |
| --- | --- |
| Flip-screen | the screen build from level data worked through one screen byte to picture; all screens as one map |
| Scrolling (pixel, character, attribute) | each layer with its speed, feed and buffer drawn; the scroll against the beam; the parallax bands on a real screenshot |
| Sprites over a background | the erase strategy (XOR, mask, back buffer, restore) drawn on one frame; the pre-shifted copies drawn; the draw order against the beam (tearing or none) |
| Attribute-only or attribute-heavy | the attribute grid as a figure; how clash is avoided or accepted |
| Pseudo-3D road | the road table, the curve and hill model, the sprite scaling, one frame built line by line |
| Isometric | the depth sort, the masks, one room built object by object |

**By engine**

| Engine | Must have |
| --- | --- |
| Script or bytecode interpreter (course scripts, AI scripts, level programs) | the full opcode table, a decoder in `tools/` that prints every script as text in `src/res`, one script traced against its recording |
| Compiled or interpreted BASIC | the BASIC listing, what the compiler or the runtime adds, the hot lines measured |
| Multi-load, 128K paging | each load or page as a stage, what stays resident, the memory map per stage |
| Copy protection, cipher, packer | section 3's full transform set; the animation of the real run |

**By port target.** When [TODO.md](TODO.md) lists a port of the game to another machine, the case gets its own document
`docs/14-porting-to-<target>.md` (13 stays for a derived case's differences). It is written after 01-10, from them
and the recordings, and must have:

- the two machines side by side: CPU and its instruction timings, memory map, video memory layout and modes, colour
  model, sound device, input, interrupts and timers, storage;
- the game's time budget per subsystem measured on the original (from the heatmap and the frame budget), and what
  each costs on the target, estimated from the target's instruction timings on the hot loops;
- each subsystem's porting plan: what moves as is (logic, tables, scripts), what is rewritten (rendering, sound,
  input, loading), and the data conversions (graphics to the target's pixel format and palette, fonts, maps, tunes),
  each with a tool in `tools/` that converts the case's `src/res` files;
- the hot routines re-thought for the target, each with pseudocode and target-assembly sketches: the number
  formats (the target's word size, multiply and divide or their absence, tables), sprite drawing for the target's
  video memory (pre-shifted copies or shifts, masks, planes), screen updates (dirty rectangles, double buffering if
  the target can), and what the target does better (a second CPU, wider words, more memory);
- what the player must not notice: the frame rate, the physics and the random sequence kept identical, and how the
  port is checked against the original (the same input script, the same positions at the same frames);
- the risks and open questions, ranked.

The planned ports, their targets and what each target's document must address are in [TODO.md](TODO.md).

**By sound**

| Sound | Must have |
| --- | --- |
| Beeper in the interrupt or blocking | the cost per frame measured, what the game loses while it plays (lost interrupts, a held loop), the tune format decoded and rendered |
| AY tracker (STC, PT3, own) | the format, the player, the register chart, every tune exported in an editable format |
| Speech or sampled sound | the sample format, the playback loop timing, the samples exported |

### 01. Game design: the game as a player meets it

- The premise, the screens and modes, from the title to the game over and the high-score entry: one screenshot each.
- **The world**: the full map rendered from the image's own data, stored in `src/res/`, with a preview in the
  document. Compare it with published maps and credit them with URLs. Give the structure: zones, levels, rooms,
  their count and order.
- **The key moments of the gameplay**, each with a screenshot and the frame it was taken at:
  - the start;
  - the first enemy;
  - every new mechanic as it first appears;
  - every power-up;
  - every boss or zone end;
  - death and respawn;
  - the end of the game.
- The rules: lives, energy, ammunition, time, scoring (a full table: what scores how much), extra lives, bonuses,
  the difficulty curve and what drives it.
- The controls as a player uses them, and every hidden key, cheat or easter egg found in the code.
- Each enemy and object kind as the player sees it: a picture, how it moves, what kills it, what it scores.

### 02. Architecture

- The machine budget, and the memory map as a figure, with the stages side by side.
- The module map: every module, its range and its role.
- The module heatmap and the frame budget: where the CPU time goes.
- The main loop's call graph (mermaid), and what runs in the interrupt and what runs in the loop.
- The 48K / 128K differences: paging, sound device, the branches that test the model, and the code that tests them.

### 03. Build and load

- The medium as a picture: blocks, sizes, addresses, times at ROM speed, pauses.
- Every BASIC line listed and explained.
- **Every loader**: what differs from the ROM's LD-BYTES, header checks, turbo timings, the error path, the
  countdown or progress display. Each gets a flowchart and the asm.
- **Every protection and cipher**: the full mechanism bar plus a worked example on the real bytes.
- **Every unpacker**: the format, both directions, a worked example, the animation of the real unpack.
- The stages from power-on to the game as a mermaid diagram, with the frames from the recording on the edges.
- The stages table and the static-decode-versus-recording check table.
- The source build: a mermaid diagram and the table of inputs.

### 04. Game loop and timing

- The state machine of the whole program as mermaid: title, menu, demo, play, death, zone end, game over and high
  score, and every transition with its trigger.
- **Interrupts**:
  - the mode, IM 1 or IM 2, with the vector table and its fill byte;
  - what the handler does, line by line;
  - where the code runs with interrupts disabled and why;
  - how the loop syncs to the frame (HALT, a frame counter, none);
  - what happens when a pass runs over a frame, with the measured pass lengths.
- The order of work inside a pass, with a beam timeline of a typical pass and of the heaviest one.
- Every delay, pause and timer, in frames and seconds, measured.

### 05. Controls

- Every device (keyboard, Kempston, Sinclair, cursor, Fuller), with its port, decoding routine and bit layout as a
  figure.
- The redefinition routine, the menu navigation, pause, abort and every hidden key.
- How the input becomes movement: the path from the port read to the hero's state, as mermaid.

### 06. Rendering

- The screen layout: the play area, the panel, the attribute use, and how colour clash is handled.
- Every draw path (screen build, tiles or elements, sprites, the hero, effects, scrolling or flip-screen), each
  with:
  - the data format as a data sheet;
  - the routine as pseudocode and asm;
  - a routine animation;
  - a code-vs-screen figure.
- Masks, mirroring, pre-shifted frames, the erase strategy (XOR, buffer, restore) and the order of drawing against
  the beam (tearing or none).
- The screen build from the level data, worked through one real screen, byte to picture.

### 07. Objects

- The object record field by field, the slots, the spawn and free paths.
- **Every object kind's behaviour as a state machine** (mermaid): enemies, missiles, pods, guns, pickups,
  teleports, platforms, bosses.
- Collision: the tests (box, cell type, pixel), their order, what each outcome does. Give a flowchart and a worked
  example.
- The random-number generator: the algorithm, its seed, its users.

### 08. HUD and text

- The panel, drawn and labelled, with every field's address, format (BCD, binary, digits) and update routine.
- The font as a data sheet, the print routine with its control codes, and every string with its address.
- The menus and the high-score table: layout, entry, sorting, saving.

### 09. Sound

- The engine type for each machine: beeper, AY, General Sound.
- How sound is timed: in the interrupt, in the loop, or blocking. Measure what it costs per frame.
- The music format, decoded byte by byte, and the player as pseudocode, a flowchart and a worked example.
- Every effect: its trigger, its parameters, its length, its priority against others, and a rendered audio file.
- The AY register writes over time as a chart. The beeper toggles as a waveform or timeline.

### 10. Gameplay logic

- The rules as code: the hero's states (mermaid), damage and death, respawn, the score and its awarding sites,
  extra lives, bonuses, the level progression and the end.
- The difficulty: what changes between zones, levels or loops, and the tables that drive it.
- Bugs and oddities found in the code, each with a witness.
- What no recording reached, and where the code shows it.

### 11-12. Generated references

Generated from the `.ann` by `kit/refdocs.py`, never edited by hand. A wrong description is fixed in the `.ann`,
then regenerated, then built until identical.

## 5. Quality gates before "done"

A document or a case is not done until it passes all of these. The lead runs them; the owner sees only what passed.

1. **The fact review** ([recipe 09](recipes/09-review.md)): fresh agents check every number, address, name and
   claim against the listing and the recordings. The lead checks every finding before fixing it.
2. **The completeness audit**: a fresh agent checks each document against sections 3 and 4 of this file and
   against the same document in the finished reference cases (Zynaps, Nether Earth, Elite).
   - **The routine map**: every routine and data block of the subsystem, taken from the `.ann`, is mapped to the
     section that explains it, or to "nothing".
   - **The bar check**: every mechanism is checked against the eight elements of section 3.
   - **The depth comparison**: wherever the reference case explains and this case only points, it is a gap.
   - **The priorities**: P1 = a mechanism unexplained; P2 = an explanation missing a diagram, example, witness
     or figure; P3 = polish.

   The report goes to `work/review/cmp<id>.md`. Done means no P1 and no P2.
3. **The figure check**: the lead views every figure at full size and at 900 px. Every label must be readable,
   nothing may be clipped, and the caption, the figure and the text must agree.
4. **The counts**: per document, sections, mermaid diagrams, figures and worked examples, compared with the
   reference case. A subsystem document with no diagram is suspect until the audit clears it.
5. **The build and checks**: `tools/build.sh` prints identical and `kit/check_docs.py` prints docs: ok.

Two rounds, then the case closes. Round 1 is the fact review plus the completeness audit. Round 2 is one pass that
checks facts and completeness together, with the halves swapped. Its findings are fixed and committed, and then the
case is done. There is no third round: the yield falls fast and the cost does not (Exolon: 47 findings, then 33).

## 6. Writing rules

- English. Hex in code spans, never in bare prose: a pair of `$` renders as math on GitHub.
- Open every document with what it covers and the recordings it rests on.
- Define a term once, in `docs/README.md`, and link to it.
- One idea per sentence. Prefer lists to long paragraphs. Put the constants in the prose before a code block, not
  in long trailing comments.
- Mermaid: no HTML entities (write `#quot;`). `check_docs.py` renders every block, and the lead views each one.
- Every figure has:
  - a title stating its point;
  - every mark labelled;
  - a "how to read" list;
  - "the point";
  - the command that drew it;
  - the recording, frames and T-states in the caption.
- Show new information only: no size bars, no duration bars.
- Figures are rendered from the recordings or the image by scripts in `tools/` or `kit/`. Never edit a picture by
  hand.

## 7. Working as an agent

**The order of work (the lead).**

- One phase follows the next without a pause: when the source is identical, the writers start the same hour. Ask the
  owner only for real decisions, never "shall I go on".
- Before launching writers, check that their port bases are free (`lsof -iTCP -sTCP:LISTEN`). A writer without an
  emulator cannot draw animations.
- Every writer brief lists, per document: the section 4 items, the profile items (section 4.0) and the animations
  (section 4). It says: each section lands with its figure, diagram and animation; no ASCII art; no link to an image
  that does not exist yet.
- Measure progress every 20 minutes by `wc -l docs/*.md`, the image links and the files under `docs/img/`. A
  document that does not grow, or grows without pictures, is stopped and corrected at once.
- Before each commit, `git status` shows every new image and GIF (none swallowed by `.gitignore`).

- **Your brief is your scope.** Edit only the files it assigns you. Shared files belong to the lead:
  - `docs/README.md`, the case README and `case.json`;
  - the merge of `.ann` fragments;
  - every commit and push.

  Send your index lines in `work/docs/<id>-index.md`.
- **Emulators**:
  - one instance per agent, muted, on your own port base from the prompt;
  - stop only the pids you started;
  - read a recording through `time_travel memory_at`, never on a running machine;
  - never seek or resume an instance you did not start;
  - never play audio.
- **Temporary files** go in the case `work/`. Never in `/tmp` and never in the case root.
- **No commits** by agents. The lead commits in this repository after each finished and checked phase.
- **Report**:
  - what you wrote;
  - every command and what it proved (`work/docs/<id>-NOTES.md`);
  - what is known only from the code;
  - for a review, the counts by kind and the most important findings.
- **Tool gaps**: what the analysis cannot name is a gap in unreal-ng. Fix it generically, with a test; never with
  a rule tuned to one game. Record it in the WALKTHROUGH's tool-gap table.

## 8. Anti-patterns seen, and the rule now

| Seen | Rule |
| --- | --- |
| Exolon 03: "the loader is Zynaps' Countdown II", "picy has Zynaps' layout", with no algorithm | section 3 item 1: every mechanism explained on its own |
| Exolon 06-09: no mermaid in four subsystem documents | section 3 item 4 and the completeness audit |
| Docs accepted after a fact review alone | section 5: the completeness audit is a gate |
| Figures unreadable at 900 px | the lead views every figure at 900 px before it is shown |
| H.A.T.E.: few figures, code and screen linked only in words | GUIDE section 4 density, code-vs-screen figures |
| The same frames given three ways in three documents | numbers from scripts, one commit changes them everywhere |
| Stage comments that read well and were wrong | a run checks a name before it goes into a description |
| A derived case written as patches on the base | a full own reverse; differences only in doc 13 ([recipe 10](recipes/10-derived-case.md)) |
| Moon Patrol: documents left as stubs for hours after the source was identical, then a question to the owner before starting them | the documents start the moment the source is identical; a stage boundary is no reason to stop |
| Moon Patrol: writers told "prose first, figures after" wrote 2 700 lines with no picture and dangling image links | each section lands with its figure, diagram and animation in the same step |
| Moon Patrol: a sprite drawn in `#` and `.` in a text block | pixels are pictures; no ASCII art anywhere |
| Moon Patrol: no animation at all, because a writer's ports were held by a foreign instance | the lead checks the port bases are free before launch; the animation minimum (section 4) is a gate |
| Moon Patrol: figures in `docs/img/build/` were silently not committed (`**/build/` in `.gitignore`) | never name a folder `build`, `work` or `output` inside `docs/`; check `git status` shows every new image |
| Moon Patrol: 8.4 frames a pass (with the bonus screens) reused as the play pass; numbers derived from it everywhere | a derived number carries its measure; recompute all of them when it changes |
| Moon Patrol: ScrollMountains scrolled the strip labelled HillsStrip | names checked against each other and against the screen |
