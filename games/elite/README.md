# Elite (Firebird, 1985)

State: complete 2026-11-07, reviewed: the full annotated source and resources, both tape
sides rebuilt byte for byte, the documents 01-12 and the articles below ([docs/README.md](docs/README.md); how they
were made: [WALKTHROUGH](WALKTHROUGH.md)).

The articles beside 01-12:

- [The ships](docs/ships.md): the 19 blueprints one by one, each turning, drawn by the game's own code
- [The 3D engine](docs/3d-engine.md): number formats, the transform, projection, visibility, the maths and its costs
- [The galaxy generator](docs/galaxy.md): the seeds, the twist, names, descriptions, the eight galaxies
- [The Lenslok](docs/lenslok.md) and [all its codes](docs/lenslok-codes.md)
- [The runtime analysis](docs/runtime-analysis.md): profiles, flame graphs, the PRNG, the beam, per-scene costs
- [The scenes](docs/scenes.md): trading, docking, kills, missiles, the galactic jump, missions, saves
- [Against BBC Elite](docs/bbc-comparison.md): what the conversion kept and changed, side by side

| | |
| --- | --- |
| Machine | 48K |
| Authors | Ian Bell and David Braben (the original, Acornsoft 1984); the conversion by Torus Ltd., (c) British Telecommunications plc, published by Firebird |
| Sound | beeper, effects only |
| Protection | Softlock on the tape ([03](docs/03-build-and-load.md)), the Lenslok on the screen ([lenslok.md](docs/lenslok.md)) |
| Original | `orig/Elite.tzx.zip` (md5 `9698e5532b62b0614dff92957d707e59`, SHA-1 `68d6ceb9d20ab2cfb37717a44baaf47dbb755c97`): `Elite - 48k - Side A.tzx` (md5 `6b0ee146cf206d997c901c0e67460c82`, SHA-1 `f56bb775dc9514109437529161778d51d68fd465`), the reference the build must reproduce, and `Elite - 48k - Side B.tzx` (the Adder in place of the Krait; md5 `9dd57ef1bb0c42315951208593719960`) |
| Also | `orig/Elite_2.tzx.zip` (md5 `4112bdb775c2fe89581c47717d514dbe`, SHA-1 `59e2cd39cda0b32195aad9e67b3d68623445f752`): another 48K dump (Side B's data) and the 128K version; `orig/Elite48.tap.zip` (md5 `a82772d1e6e05130070afc3ab2d80c37`, SHA-1 `c7baec968b68064f1621eb85c496e1aca08f2e7b`): the crack `ELITE48.TAP`, no Softlock, the Lenslok patched ([lenslok.md](docs/lenslok.md) 7); `orig/Elite.txt` (md5 `36f1c2fdc06157a24dd96d2261262c46`): the instructions ([texts](docs/texts/README.md)) |

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS]     # build/Elite-SideA.tzx, compared byte for byte with orig/Elite.tzx.zip's Side A
```

It prints `build: Elite-SideA.tzx identical to orig/Elite.tzx.zip's Side A`. Needs sjasmplus and Python 3 with
Pillow.

The game source is `src/game/*.asm` (26 modules), written by `kit/mkgame.py --install` from `src/game/game.ann`
(SkoolKit in a venv); the Lenslok check is its own part (`src/lenslok/`); the tape parts are `src/tape/` (the BASIC
and the stub, Softlock, the block list); the resources are `src/res/` (`src/res/README.md`). How the parts fit:
[03](docs/03-build-and-load.md) 3.10.

## The Lenslok without the lens

`python3 tools/lenslok_answer.py SEED` prints the code the game asks for, from the seed word at `$C784` (two
`LD A,R`), computed the way the game computes it; [lenslok-codes.md](docs/lenslok-codes.md) lists all 475 codes.
The case never patches the game to get past it.

## Credits and provenance

The reverse is made from the tape and the emulator's recordings. These works were read to cross-check it, never as
a source of bytes or names ([WALKTHROUGH](WALKTHROUGH.md) 7):

- [elite-skoolkit](https://github.com/Rasmus-M/elite-skoolkit) by Rasmus M: a SkoolKit disassembly of the cracked
  `ELITE48.TAP` (the same file as `orig/Elite48.tap.zip`'s);
- [zx-elite](https://github.com/ataribaby42/zx-elite) by ataribaby42: notes on the Spectrum game's data structures
  and routines;
- [EliteNext](https://github.com/TinfoilAsteroid/EliteNext) by TinfoilAsteroid: Elite for the ZX Spectrum Next;
- [bbcelite.com](https://www.bbcelite.com) by Mark Moxon: the BBC Micro original, fully documented.

The tape files come from the World of Spectrum archive; the Lenslok instructions, the keyboard overlay and the
inlay scans from ZXDB (spectrumcomputing.co.uk).
