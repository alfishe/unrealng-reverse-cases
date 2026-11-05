# Zynaps (Hewson Consultants, 1987)

State: in progress, stage 1 (the load, the map, the state; no source yet).

| | |
| --- | --- |
| Machine | 48K |
| Authors | Dominic Robinson (code, graphics), Steve Crow (graphics), Steve Turner (music) |
| Sound | beeper |
| Original | `orig/Zynaps.tzx.zip` (md5 `af3a609859672dad2c585811c12cdb97`, SHA-1 `3b769816a9d573e938f128d8ae0b9c5ba2903386`): `Zynaps.tzx` (md5 `a7c8e12d565f513c01d29446cee9e54f`, SHA-1 `60511d70de1b7c916666e5b68acdc3f8de0ccad6`), the reference the build must reproduce |
| Also | `orig/Zynaps.tap.zip` (md5 `6f11bbfdad6ddf765af99d7bf047f160`, SHA-1 `f2363ddfb58229e3e54c418d24998e625955fd64`): a 1993 re-tape ("DRJ 3/12/93") of the same game without the Hewson loader, [03](docs/03-build-and-load.md) 3.6 |

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

Not written yet (stage 2). The target:

```bash
tools/build.sh [SJASMPLUS]     # builds build/Zynaps.tzx and compares it with orig/Zynaps.tzx.zip's TZX byte for byte
```

The game source is `src/game/*.asm`, written by `kit/mkgame.py` from `src/game/game.ann`; the resources are
`src/res/` (`src/res/README.md`).
