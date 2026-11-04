# Nether Earth Editor (V.O.software, 1996)

State: source, resources and documents complete (2026-11-04); the tape rebuilds byte for byte.

| | |
| --- | --- |
| Machine | 48K |
| Authors | Vovanius, V.O.software (Russia), 1996, freeware (ZXDB entry 17113, "editor for" entry 3391) |
| Original | `orig/NetherEarthEditor.tzx.zip` (md5 67fa7894efdf0d40902ad6a11aee5915, SHA-1 12d0f50474fdcd0888095a7a424d89ca19d72ca1), the ZXDB download `/pub/sinclair/utils/n/NetherEarthEditor.tzx.zip`, holding `orig/NETHER.TZX` (md5 06c8ed1022b074650b61687b17554f42, SHA-1 8818b4beaf9606f1dd3222120f509282ab3368bc) |

A level editor for [Nether Earth](../nether-earth/README.md). The tape holds three things:

- **the game**: a snapshot of the original Nether Earth taken in its main menu, with a small loader. The image from
  `$5B00` up is the original's byte for byte: no crack, no patch, no translation ([3.5](docs/03-build-and-load.md#35-the-image-against-nether-earths));
- **seven levels** by V.O.software as saved games, loaded with the game's own LOAD SAVED GAME: Enemy At The Gates,
  Break Through, Fortifications, The Chase, Jungle Of Stone, Double Frontline, The Slogan ([1.3](docs/01-game-design.md#13-the-levels));
- **the editor**: two BASIC programs and 2244 bytes of machine code (`nee.mix`) that draw the map, place the bases and
  set the resources, and save a level in the game's format ([2](docs/02-architecture.md), [5](docs/05-controls.md)).

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS [PYTHON]]   # builds build/edition/NETHER.TZX and compares it with orig/NETHER.TZX
```

PYTHON needs SkoolKit (the BASIC tokeniser computes the ROM's inexact numbers with SkoolKit's simulator). The game's
image comes from [Nether Earth's own source](../nether-earth/src/game/game.asm), assembled into this case's build
folder; the 48K ROM from the unreal-ng submodule.

| What | Source |
| --- | --- |
| the game edition | `src/edition/edition.asm` (the loader, the trampoline, the snapshot's state bytes) + Nether Earth's source + `src/res/edition/menu-screen.scr` |
| the levels | `src/res/levels/*.txt`, one editable text file a level (`tools/levels.py`: the format in its docstring) |
| the editor | `src/basic/ne-editor.bas`, `src/basic/nee.bas` (commented listings, `tools/zxbasic.py`), `src/basic/nee-rem.asm`, `src/mix/mix.asm` (written by `kit/mkgame.py` from `src/mix/mix.ann`, every routine named and commented), `src/res/mix/*.png` (tiles and font) |

To write `nee.mix`'s source again from its annotations: `tools/mkmix.sh SKOOLKIT_VENV SJASMPLUS` (needs the
recordings in `work/edB`, see the WALKTHROUGH).
