# Nether Earth (Argus Press Software, 1987)

State: source, resources and documents complete (2026-11-04); the tape rebuilds byte for byte.

| | |
| --- | --- |
| Machine | 48K |
| Authors | Javier Cano (design and code, per ZXDB; the game names no author, the BASIC's REM only "(c)1986 APS") |
| Original | `orig/NETHER.TZX` (md5 b63b464eeab396134594d3952aec7af2, SHA-1 5a08d3cb2a04820ae870615aae188140e5be19a9), the World of Spectrum TZX; `orig/NETHER.TAP` (md5 391c54bb604d1a1dbd4df9262c36f643) is the Mind Games España release, the same five blocks byte for byte |

The TOSEC "Nether Earth (1987)(Argus Press Software).tap" is not the original: its BASIC says "CRACKED BY BILL
GILBERT'87" and the game is one 42240-byte block.

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS]     # builds build/NETHER.TAP and compares it with orig/NETHER.TAP byte for byte
```

The game source is `src/game/*.asm`, written by `kit/mkgame.py` from `src/game/game.ann`; the resources are
`src/res/` (`src/res/README.md`): the font, 89 sprites, the view edges, the map scenery and shapes, the menu music
and the order names, in editable formats that `tools/res_formats.py` builds back to the original bytes.

To write the source again from the annotations (from the repository root; SkoolKit in a venv):

```bash
python3 kit/mkgame.py --case games/nether-earth --venv SKOOLKIT_VENV --sjasmplus SJASMPLUS --install
python3 kit/refdocs.py --case games/nether-earth       # docs/11 and docs/12
python3 kit/check_docs.py --case games/nether-earth
```

| What | Size |
| --- | --- |
| `src/game/*.asm` | 22 modules, 564 entries: every routine and data block named and described, every instruction commented |
| `docs/` | 12 documents, 44 figures from the recordings |
| `tools/` | the bot that played the recorded games (`bot.py`), the resource formats, the figure scripts |
