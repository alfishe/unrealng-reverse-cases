# The page-4 engine's data

| File | Address | Size | Format | Read by |
| --- | --- | --- | --- | --- |
| `engine-data.txt` | `$DE48`-`$FE6F` (page 4) | 8232 bytes | the period, envelope and sound tables with the blocks they point at, as text (`tools/sound_data.py`, the format in its docstring) | the page-4 engine at `$C968` (`src/sound/engine.asm`): `PlayNote` reads `PeriodTable`, the envelope commands read `EnvelopeTable`, `StartSound` and `CmdCall` read `SoundTable` |

`tools/build_sound.sh` encodes it into `build/sound/engine-data-de48.bin`; block 1 includes that with `INCBIN` and
the intro copies it to page 4. `python3 tools/sound_data.py check src/res/sound/engine-data.txt
work/parts/engine-data-de48.bin` proves the round trip.

The parts:

| Block | Address | What |
| --- | --- | --- |
| `[periods]` | `$DE48`, 95 words | the tone period of notes 0-94; notes 0-12 are 0, note 13 is 4126 and each next note a tempered semitone higher |
| `[envelopes]` | `$DF06`, 35 words | envelopes 0-30 (`e00`-`e1E`), then four 0 words |
| `[raw]` | `$DF4C`, 1 byte | a 0 between the tables, read by nothing |
| `[sounds]` | `$DF4D`, 36 words | sounds 0-35: `s0B`, `s0C`, `s0D` are the music's channels A, B, C, `s0E`-`s1F` the effects |
| `[sound sNN]` | from `$DF95` | each sound's commands (notes, rests, envelopes, calls, transpositions, `swap`, `return`, `end`) |
| `[envelope eNN]` | | each envelope's steps (frames, change, repeats) and its `loop` |
| `[raw]` | | bytes no table reaches: the zero runs and a few fragments |

Rewritten at run time: `SoundTable`'s first two words. The command `swap` (`$EC`, `CmdSwap`) swaps sounds 0 and 1;
the music's channel B runs it once a pass (in `s0C`), and all three channels call sounds 0 and 1. A pass of the tune
is 10 304 frames; channel A's registers repeat only every second pass (20 608 frames, `tools/sound_render.py loop
game --frames 40000`). The file holds the loaded order (`s00 s01`). Nothing else in the data is written by the engine. The
data in the recordings at the menu (`work/images/menu-bank4.bin`) and at the game's entry
(`game-entry-bank4.bin`) equals the loaded bytes; in play (`play-bank4.bin`) only `$FDC3`-`$FDCE` differ. These bytes
are inside the last zero run: they hold the words `$CC46`, `$CCCB`, `$CA9E`, `$CA87`, `$5B12`, `$5B12` (pushed registers and return
addresses into the engine and the glue) from the game's stack.
The stack lies in page 4 while the glue's interrupt handler has page 4 paged in.

The four zero runs, `$DFFF`-`$E63F`, `$E7FF`-`$EE3F`, `$EFFF`-`$F63F` and `$F7FE`-`$FE47`, are the CPC's screen
memory. On the Amstrad the data lies at the same addresses inside the screen at `$C000`-`$FFFF`. Each 2K block there
holds one pixel line of the screen: its first 1600 bytes are pixels, and the data fills the 448 free bytes at
`$x640`-`$x7FF`. The data starts at `$DE48`, just after the `$D800` block's pixels end at `$DE3F`. The ZX copy has
zeros where the CPC rip (`work/stage2/sound/cpc/`) has screen pixels. All 2530 bytes that differ from the rip after
the period table lie in these runs (docs/09-sound.md 9.6).

Note names: note 13 is A0 at the ZX AY clock (1.7734 MHz: 26.86 Hz, 40 cents below a tempered A0). The CPC played the
same note numbers from a table 12 notes lower (docs/09-sound.md 9.6).
