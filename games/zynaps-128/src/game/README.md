# Block 2: the game and its 128K layer

Block 2 unpacked, `$6000`-`$FB84` (39 813 bytes), assembled to the original's bytes; `tools/build.sh` then packs it
with `tools/hrust1.py` into sectors 58-136 of `ZYNAPS.B`. [docs/03-build-and-load.md](../../docs/03-build-and-load.md)
3.5-3.6, [docs/09-sound.md](../../docs/09-sound.md) 9.2.

| Source | Annotations | Built | Runs at | What |
| --- | --- | --- | --- | --- |
| `block2.asm` + `setup.asm` | `setup.ann` | `build/obj/block2.bin` | `$6000` | the set-up: the game moved to `$6800`-`$FFFF`, the 128K layer installed (when the loader found a 128K), the options, `JP $8000`; then the parts below and the game, by `INCBIN` |
| `hooks.asm` + `stubs.asm` | `stubs.ann` | `build/obj/stubs-b30d.bin` | `$B30D` | the shared stub and the 15 hooks: one page-4 effect at each event the 48K game beeped at |
| `glue128.asm` + `glue.asm` | `glue.ann` | `build/obj/glue-5b00.bin` | `$5B00` | the 128K glue: the engine each frame from the game's interrupt, the music on and off, the patches it writes |
| `kmouse.asm` + `mouse.asm` | `mouse.ann` | `build/obj/mouse-fe00.bin` | `$FE00` | the Kempston mouse driver (option K-MOUSE) |

The 48K game itself (`$6800`-`$FFFF` as it runs, 38 912 bytes) is one resource, `src/res/game/game-6800.bin`, until
the 48K case's `game.ann` (`../zynaps/src/game/game.ann`) is complete: this case's `game.ann` will then be seeded from
it for the identical bytes, with the 11 changed places of the 2 in 1 annotated (docs/03 3.6). The `.asm` files are
written from the `.ann` files by `tools/part_mkasm.py` (`tools/mkasm_all.sh`); edit the `.ann`.
