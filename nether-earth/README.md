# Nether Earth (Argus Press Software, 1987)

State: in progress.

| | |
| --- | --- |
| Machine | 48K |
| Authors | (from the game's own credits, once read) |
| Original | `orig/NETHER.TZX` (md5 b63b464eeab396134594d3952aec7af2, SHA-1 5a08d3cb2a04820ae870615aae188140e5be19a9), the World of Spectrum TZX; `orig/NETHER.TAP` (md5 391c54bb604d1a1dbd4df9262c36f643) is the Mind Games España release, the same five blocks byte for byte |

The TOSEC "Nether Earth (1987)(Argus Press Software).tap" is not the original: its BASIC says "CRACKED BY BILL
GILBERT'87" and the game is one 42240-byte block.

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS]     # builds build/NETHER.TAP and compares it with orig/NETHER.TAP byte for byte
```

The game source is `src/game/*.asm`, written by `kit/mkgame.py` from `src/game/game.ann`; the resources are
`src/res/` (`src/res/README.md`).
