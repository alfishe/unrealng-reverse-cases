# unreal-ng reverse cases

Complete reverse-engineering cases of ZX Spectrum games done with the
[unreal-ng](https://github.com/alfishe/unreal-ng) emulator's analysis tooling: memory access counters, port traces,
the profiler, time-travel debugging (TTD) and the analysis layers (L0 access facts, L1 routines and value flow, L2
region kinds, L3 findings and experiments), driven through MCP.

Every case is one folder per game:

| Path | What it holds |
| --- | --- |
| `<game>/README.md` | the game's documentation: architecture, memory map, every subsystem, data formats |
| `<game>/WALKTHROUGH.md` | how the reverse was done, step by step, and which emulator capability answered each question |
| `<game>/src/` | the annotated source that rebuilds the original tape byte for byte |
| `<game>/tools/` | the build (assembler, packer, tape writer) and the extraction scripts |
| `<game>/orig/` | the original distribution, unchanged |

## Cases

| Game | Publisher, year | State |
| --- | --- | --- |
| [H.A.T.E.](hate/README.md) | Vortex Software, 1989 | in progress |
