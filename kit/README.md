# kit: the scripts every case shares

The case standard is [GUIDE.md](../GUIDE.md), the steps are [recipes/](../recipes/README.md). These scripts do the
work that is the same in every game; what is particular to one game (its packer, its resource formats, its bot)
stays in the case's own `tools/`.

They need Python 3 with Pillow, and an unreal-ng checkout for the access trace reader and `re_session.py`. The
checkout is found from `--unreal`, `$UNREAL_NG`, the `unreal-ng` submodule, or one next to this repository. `mkgame.py` also needs SkoolKit (a
virtualenv: `--venv`) and sjasmplus.

## A case

| Script | Does |
| --- | --- |
| `case-template/` | the skeleton of a new case: README, WALKTHROUGH sections, the twelve documents with their figure lists, `case.json`, `src/game/game.ann`, `src/res/README.md`, `tools/build.sh`, a bytes-only `tools/res_formats.py` |
| `tapblocks.py list FILE.tap` | the blocks of a tape: lengths, header fields, the play time at ROM speed, checksums |
| `tapblocks.py FILE.tap N OUT` | one block's data |
| `tap.py` | writes a tape of standard ROM blocks (the build's last step) |
| `mkgame.py --case C` | `src/game/*.asm` from `game.ann`, the recordings' `l1.json` and the image `case.json` names; refuses to install unless sjasmplus gives the image's bytes |
| `ann_names.py --case C ADDR=Name ...` | names labels inside entries of `game.ann` |
| `input_vars.py --work W --inputs S --start F` | the bytes that follow the held directions and fire over a scripted recording: a first guess at the player's coordinates (a 16-bit coordinate, or one that moves only now and then, scores low: confirm in the code that reads the controls) |
| `refdocs.py --case C` | docs 11 and 12 from `game.ann` and the recordings; doc 12 links `docs/img/routines/<Label>.gif` |
| `check_docs.py --case C` | mermaid renders, links resolve, no `$` in prose, every figure in `docs/img` is linked |
| `code_addresses.py FILE.md` | puts hex addresses in prose into code spans |

`case.json` (the template's is the example):

| Key | Meaning |
| --- | --- |
| `image` / `image_cmd` | the 64 K image as the loader leaves it; the command (run in the case) that writes it |
| `lo`, `hi` | the bytes of the image that are the game (hex; `hi` exclusive) |
| `device` | sjasmplus `DEVICE` |
| `bases` | L1 page -> Z80 base of each bank of the image |
| `read_builds` | the `work/<build>` whose data reads count (not those over a depacker's input) |
| `ref_builds` | `[key, text]` of the builds docs 11 and 12 report |
| `overlay` | a buffer laid over code once play starts (`lo`, `hi`, `name`, `why`), optional |
| `header`, `data_note` | the first comment lines of `game.asm`; a sentence for doc 11, optional |

## Figures

GUIDE.md 4 says which figure goes where. All share one palette (`kitlib.py`): executed green, read blue, written
yellow fading through red, trails dark.

| Script | Draws | From |
| --- | --- | --- |
| `routine_anim.py` | a routine at work: memory map lit by age, the screen or buffer it draws into, the listing window, the registers | an access trace |
| `writers_map.py` | code vs screen: each byte of the screen or a buffer coloured by the routine (or instruction) that wrote it, the data it read, a zoom | an access trace |
| `beam_timeline.py` | code vs the beam: the routines along a frame's T-states, every screen write against the raster | an access trace |
| `memanim.py` | memory over a longer stretch (a load, an unpack, a level set-up) | `memory_at` samples |
| `screen_anim.py` | the screen over frames | `memory_at` samples |
| `screen_shot.py` | the screen at named moments | `memory_at` |
| `heatmap.py` | executed / read / written per byte over a build | `l1.json` |
| `zxscreen.py` | a 6912-byte screen or a 64 K image to PNG | a file |

The access trace is unreal-ng's `analysis trace` (docs/emulator/analysis/analysis-layers.md, "Access trace"): one
replay of a window of a recording, every instruction with its registers and every bus cycle after it. The three
trace scripts take it as a file (`--trace`) or trace it themselves from the instance that holds the recording:

```bash
python3 kit/routine_anim.py --work $C/work/p2 --window 1001:5336-1001:45336 --listing $C/build/game.lst \
    --view buffer:8000:128x128:columns-up --pc EAE3-EBA9 --range 8000-FFFF \
    --out $C/docs/img/routines/DrawSprites.gif
```

A buffer view is `buffer:ADDR:WxH` (W bytes across, H lines) with its storage order: `:rows` (the default, a
linear bitmap), `:columns` (column by column, H bytes a column, top first), `:columns-up` (the same, bottom first:
the H.A.T.E. playfield's strips). The GIFs share one palette and store each picture as its changes, so a routine
animation of 90 pictures stays near 1 MB.

`--window F:T-F:T` is in TTD units, as `time_travel` gives them; the trace is kept in `W/traces/` and read from
there the next time.
