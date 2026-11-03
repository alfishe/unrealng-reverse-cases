# H.A.T.E. (Hostile All-Terrain Encounter)

Vortex Software, 1989, ZX Spectrum 48K. Design and code by Costa Panayi, music by Ben Daglish. Released as freeware by
Vortex in 1995 (`orig/VORTEX.TXT`).

This folder is a complete reverse of the tape release: documentation written as the design and technical
documents of the game would be if it were developed today, and a source tree that rebuilds `orig/HATE.TAP` byte for
byte.

| Path | What it holds |
| --- | --- |
| [docs/](docs/README.md) | the documentation: game design, architecture, technical design of every subsystem and routine |
| [WALKTHROUGH.md](WALKTHROUGH.md) | how the reverse was done with unreal-ng, step by step |
| `src/` | the annotated source of every stage on the tape |
| [src/res/](src/res/README.md) | the resources: graphics, screens, courses, the title tune, leftovers, as the original bytes (`INCBIN`); every file listed with its format |
| `tools/` | the build (assembler, packer, tape writer) and the extraction scripts |
| `orig/` | the original distribution, unchanged |
| `work/` | the emulator's recordings and analysis builds (not part of the deliverable) |

State: in progress.
