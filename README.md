# unreal-ng reverse cases

Complete reverse-engineering cases of ZX Spectrum games done with the
[unreal-ng](https://github.com/alfishe/unreal-ng) emulator's analysis tooling: memory access counters, port traces,
the profiler, time-travel debugging (TTD) and the analysis layers (L0 access facts, L1 routines and value flow, L2
region kinds, L3 findings and experiments), driven through MCP.

How a case is made: [GUIDE.md](GUIDE.md) (the standard: deliverables, evidence, documents, figures, phases),
[recipes/](recipes/README.md) (the steps, phase by phase), [kit/](kit/README.md) (the shared scripts: source
generation, reference documents, routine animations, code vs screen maps, beam timelines). The emulator side, which
call answers which question over MCP: unreal-ng's `.recipe/articles/game-reverse-case.md`.

Every case is one folder per game:

| Path | What it holds |
| --- | --- |
| `<game>/README.md` | the game's documentation: architecture, memory map, every subsystem, data formats |
| `<game>/WALKTHROUGH.md` | how the reverse was done, step by step, and which emulator capability answered each question |
| `<game>/src/` | the annotated source that rebuilds the original tape byte for byte |
| `<game>/tools/` | what is particular to the game: its packer, resource formats, bot, checks; the rest is `kit/` |
| `<game>/case.json` | what the kit needs to know of the game: the image, its range, the builds |
| `<game>/orig/` | the original distribution, unchanged |

## Cases

| Game | Publisher, year | State |
| --- | --- | --- |
| [H.A.T.E.](hate/README.md) | Vortex Software, 1989 | closed 2026-11-03 |
