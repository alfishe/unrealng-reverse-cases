# unreal-ng reverse cases

Complete reverse-engineering cases of ZX Spectrum games, done with the
[unreal-ng](https://github.com/alfishe/unreal-ng) emulator's analysis tooling: memory access counters, port traces,
the profiler, time-travel debugging (TTD) and the analysis layers (L0 access facts, L1 routines and value flow, L2
region kinds, L3 findings and experiments), driven through MCP.

Each case is a full reverse of one game:

- an annotated [sjasmplus](https://github.com/z00m128/sjasmplus) source in which every routine and data block is named
  and described, and which **assembles to the original tape bit for bit** (the build compares it with the original
  and fails on any difference);
- the game's resources (graphics, maps, music, text) extracted to editable files that build back to the same bytes;
- documentation written as the game's design and technical documents would be if it were developed today, with
  figures taken from recordings of the running game;
- a walkthrough of how the reverse was done and which emulator capability answered each question.

> **Educational purpose only.** This repository exists to study and teach how these programs work and how to reverse
> engineer software with an emulator. It is not a way to obtain the games. See [Rights](#rights).

## Cases

| Game | Publisher, year | Machine, medium | State | What it is |
| --- | --- | --- | --- | --- |
| [Nether Earth](games/nether-earth/README.md) | Argus Press Software, 1987 | 48K, tape | complete 2026-11-04 | the robot strategy game: the base of five derived cases |
| [H.A.T.E.](games/hate/README.md) | Vortex Software, 1989 | 48K, tape | closed 2026-11-03 | an isometric shoot-'em-up, freeware since 1995 |
| [Nether Earth Editor](games/nether-earth-editor/README.md) | V.O.software, 1996 | 48K, tape | complete 2026-11-04 | a level editor for Nether Earth: a BASIC program with machine-code help, and seven levels as saved games |
| [Advanced Nether Earth](games/advanced-nether-earth/README.md) | Eternity Industry, 1998 | Pentagon 128, TR-DOS | complete 2026-11-04 | a Russian 128K remake: AY music, a Cyrillic font, a boot menu, disk save and two endings; doc 13 the differences |
| [Nether Earth ZS Edition](games/nether-earth-zs-edition/README.md) | Sergey Zotov, 1998 / 1999 | 128K, TR-DOS | complete 2026-11-05 | two Russian editions, nine parts reversed one by one, the '99 with its own packer; doc 13 the differences |
| [Nether Earth GS](games/nether-earth-gs/README.md) | Tron Z, 2002; tape: Hood, 2017 | 128K + General Sound, TR-DOS and tape | complete 2026-11-05 | the game with General Sound music and effects, on SCL, TRD and TAP; doc 13 the differences |
| [Zynaps](games/zynaps/README.md) | Hewson Consultants, 1987 | 48K, tape | documents 01-12 complete | the horizontal shoot-'em-up: the base of two derived cases |
| [Zynaps 2 in 1](games/zynaps-128/README.md) | goodboy and tiboh, 2018 | 128K, TR-DOS | done | Zynaps with the Amstrad CPC version's AY music and effects, a mouse option, a 48K branch; doc 13 the differences |
| [Zynaps GS](games/zynaps-gs/README.md) | ZX-Masters, 1997 | 128K + General Sound, TR-DOS | documents stage, 01-13 written | Zynaps patched for General Sound: 13 MOD tunes and 22 effects, a Trush-packed disk, an installer; doc 13 the differences |
| [Elite](games/elite/README.md) | Firebird (Torus), 1985 | 48K, tape | complete 2026-11-07 | the space trading game: Softlock and the Lenslok answered by computing them, a generated galaxy, a wireframe 3D engine, a runtime analysis and a trading course run on the game's own market code |
| [Exolon](games/exolon/README.md) | Hewson Consultants, 1987 | 48K / 128K, tape | complete 2026-11-08 | Raffaele Cecco's run-and-gun shoot-'em-up, on Zynaps' Countdown II loader |
| [Moon Patrol](games/moon-patrol/README.md) | Atarisoft (UK), 1984 (never released, recovered) | 48K, tape | complete 2026-11-09 | the arcade game's licensed port: a scrolling moon buggy, two courses, a hi-score table saved to tape |
| [Video Pool](games/video-pool/README.md) | Oxford Computer Publishing, 1985 | 48K, tape | complete 2026-11-09 | James Hutchby's pool simulation: "flicker-free" balls, three rule variations, a table editor, a turbo loader with a checksum; a UKNC port planned (doc 14) |
| [Chuckie Egg](games/chuckie-egg/README.md) | A'n'F Software, 1983 | 48K, tape | complete 2026-11-10 | Nigel Alderton's platform game: Hen-House Harry collects a dozen eggs on each of eight levels that repeat with changes, hens on the ladders, a caged duck; a two-byte tape block in ERR_SP as the protection |

Every case is one folder in `games/`:

| Path | What it holds |
| --- | --- |
| `games/<game>/README.md` | the case's summary: the original, the build, the state |
| `games/<game>/docs/` | the game's documentation: architecture, memory map, every subsystem, data formats, references |
| `games/<game>/WALKTHROUGH.md` | how the reverse was done, step by step, and which emulator capability answered each question |
| `games/<game>/src/` | the annotated source that rebuilds the original tape byte for byte, and the resources |
| `games/<game>/tools/` | what is particular to the game: its packer, resource formats, bot, figure scripts; the rest is `kit/` |
| `games/<game>/case.json` | what the kit needs to know of the game: the image, its range, the builds |
| `games/<game>/orig/` | the original distribution, unchanged |

The rest of the repository:

| Path | What it holds |
| --- | --- |
| [AGENTS.md](AGENTS.md) | the rules for every agent: the method, the evidence, the mechanism bar, what each document must cover, the quality gates (a completeness audit next to the fact review) |
| [GUIDE.md](GUIDE.md) | the case standard: deliverables, evidence, documents, figures, phases |
| [recipes/](recipes/README.md) | the steps, phase by phase |
| [kit/](kit/README.md) | the shared scripts: source generation, reference documents, routine animations, code vs screen maps, beam timelines |
| [signatures/](signatures/README.md) | the signature base: known players, packers, protections, loaders, routines and the cases' modules, with an index for scans ([format](docs/signature-format.md)) |
| docs/ | the repository's own formats: the annotation file ([ann-format.md](docs/ann-format.md)), the files of a case and where each comes from ([case-files.md](docs/case-files.md)), the signature metadata ([signature-format.md](docs/signature-format.md)) |
| `unreal-ng/` | the emulator, as a git submodule: the analysis scripts the kit uses, and the emulator to record new runs |

How to drive the emulator over MCP for a case: unreal-ng's
[game-reverse-case recipe](https://github.com/alfishe/unreal-ng/blob/master/.recipe/articles/game-reverse-case.md).

## Getting started

```bash
git clone --recurse-submodules https://github.com/alfishe/unrealng-reverse-cases.git
cd unrealng-reverse-cases
# or, in a clone made without --recurse-submodules:
git submodule update --init
```

Building a game needs only [sjasmplus](https://github.com/z00m128/sjasmplus) (tested with 1.23.1) and Python 3:

```bash
games/nether-earth/tools/build.sh /path/to/sjasmplus   # -> build: identical to orig/NETHER.TAP
games/hate/tools/build.sh /path/to/sjasmplus           # -> build: HATE.TAP identical to orig/HATE.TAP
```

Regenerating a source from its annotations, the reference documents and the figures needs more:

| Tool | For |
| --- | --- |
| Python 3 with [Pillow](https://python-pillow.org/) | every kit script, the resource formats, the figures |
| [SkoolKit](https://skoolkit.ca/) (10.x, in a venv) | `kit/mkgame.py`: annotations to source |
| unreal-ng, built from the submodule (`unreal-ng/README.md`) | recording new runs, the MCP analysis, the access traces |

The recordings themselves (`games/<game>/work/`: TTD sessions, analysis builds, traces) are not in the repository:
they are tens of megabytes each and are reproduced from each case's WALKTHROUGH.

## License

The work in this repository (the annotations and comments of the sources, the documentation, the figures, the
recipes, the kit and the case tools) is licensed under the
[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-nc-sa/4.0/)
license ([LICENSE](LICENSE)).

## Rights

The games themselves (their code, graphics, music, text and the original tapes in `games/<game>/orig/`), and
therefore the program bytes that the sources reproduce, remain the property of their respective copyright holders.
No ownership of them is claimed, and the license above does not cover them. They are included only for education and
research: to study how the programs work and to verify that the reverse is exact.

- H.A.T.E. was released as freeware by Vortex Software in 1995 (`games/hate/orig/VORTEX.TXT`).
- Nether Earth: (c) Argus Press Software.
- The other games and conversions: (c) their authors and publishers, named in each case's README.

If you hold the rights to a game here and want it removed, open an issue and it will be taken down.

The unreal-ng emulator in `unreal-ng/` is a separate project under its own license.
