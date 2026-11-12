# GAME (PUBLISHER, YEAR)

State: in progress.

| | |
| --- | --- |
| Machine | 48K |
| Authors | |
| Original | `orig/GAME.TAP` (md5 ..., SHA-1 ...) |

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS]     # builds build/GAME.TAP and compares it with orig/GAME.TAP byte for byte
```

The game source is `src/game/*.asm`, written by `kit/mkgame.py` from `src/game/game.ann`; the resources are
`src/res/` (`src/res/README.md`).
<!-- A program that is not a game: the case is software/<name>, the source src/main from src/main/main.ann
     (case.json "main": "main"); recipes/01-start-a-case.md step 1. -->
