# The two music players

Both are block 1's bytes (the intro copies them where they run) and are assembled to the original's bytes by
`tools/build_sound.sh` into `build/sound/`, which block 1 includes with `INCBIN`.
[docs/09-sound.md](../../docs/09-sound.md) describes them.

| File | What |
| --- | --- |
| `starkos.asm` | the top file of the STarKos player with the song SK10 (`$8000`-`$90C4`, 4293 bytes; block 1 `$D810`): `SAVEBIN build/sound/starkos-8000.bin` |
| `starkos-play.asm` | the entries, `Init`'s song pointers and `Play`: the speed, the pattern streams, the special track and the three tracks |
| `starkos-frame.asm` | every frame: the three instruments (`PlayInstruments`), the track line format (`ReadTrackLine`), the instrument line format (`InstrumentLine`, `HardLine`) |
| `starkos-output.asm` | the CPC period table, `SendRegisters` (only the changed registers), `Stop`, `Init` and its reset table |
| `starkos-song.asm` | `INCBIN "build/sound/sk10.bin"`, from `src/res/music/sk10.txt` |
| `starkos.ann` | the annotations the five files are written from |
| `engine.asm` | the top file of the page-4 engine (`$C968`-`$CD22`, 955 bytes; block 1 `$632D`): `SAVEBIN build/sound/engine-c968.bin` |
| `engine-entries.asm` | the jump table, the effect entries, starting and stopping, sending the AY registers |
| `engine-play.asm` | `PlayFrame`: the channels' commands, the notes, the volume, pitch and noise envelopes |
| `engine-state.asm` | the AY register image and the three channel records |
| `engine.ann` | the annotations the four files are written from |

The `.asm` files are written by `tools/part_mkasm.py`; edit the `.ann`, not the `.asm`:

```sh
python3 tools/part_mkasm.py --image work/parts/starkos-8000.bin --org '$8000' --ann src/sound/starkos.ann \
    --top starkos --dest src/sound --res src/res --l1 work/stage2/intro/l1.json \
    --title "The STarKos player and the intro tune SK10" --out work/stage2/sound/mk/starkos \
    --built music/sk10.bin=build/sound/sk10.bin --save build/sound/starkos-8000.bin --install
python3 tools/part_mkasm.py --image work/parts/engine-c968.bin --org '$C968' --ann src/sound/engine.ann \
    --top engine --dest src/sound --res src/res --l1 work/stage2/game/l1.json \
    --title "The page-4 sound engine of the 128K game" --out work/stage2/sound/mk/engine \
    --save build/sound/engine-c968.bin --install
```

The `--built` song must exist first (`sh tools/build_sound.sh` makes it). The engine's data
(`$DE48`-`$FE6F`) is not code: it is the text `src/res/sound/engine-data.txt` (`tools/sound_data.py`), and
`engine.ann` names its three tables with `@equ`.
