# Zynaps 2 in 1: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

`tools/disk.py list` / `compare` on the SCL and the TRD: one BASIC file `ZYNAPS.B` (137 sectors, a loader in a REM)
in both, plus a generic `boot.B` on the TRD. `tools/hrust1.py` unpacks the two `HR` blocks inside it. Details:
[docs/03-build-and-load.md](docs/03-build-and-load.md) 3.1-3.3; the commands: `work/stage1/NOTES.md`.

## 1. One recording from power-on

`c1`: `re_session.py capture --record-load` on Pentagon 128 + TR-DOS with the TRD, keys from
`work/stage1/inputs/c1-trd-pentagon.txt` (the 128 menu, `RUN`, the boot list, the intro, the menu, random play);
recording frame = script frame + 1602, no fast load (a disk). The same keys on every 128K-or-larger model with
TR-DOS: `tools/model_run.py` (docs/03 3.9).

## 2. Static pass over the medium

`tools/parts.py` cuts every code image from the TRD with no recording: ZYNAPS.B's BASIC, the depacker, both blocks
packed and unpacked, the intro's parts (the code, the page-4 engine and its data, the STarKos player with its song),
block 2's parts (the set-up, the hook stubs, the 128K glue, the mouse driver, the 48K game) and boot.B, each at the
address it runs at (`work/parts/`, the list in its docstring).

## 3. The stages and the packers

`re_session.py stages` and `tools/first_change.py` (a binary search over `time_travel memory_at`) give the frames of
each stage; `tools/ttd_dump.py` the six images in `work/images/`; Hrust 1 proved at 0 bytes different for both
blocks (docs/03 3.3, 3.7). The sound hooks: `time_travel coverage_scan` on each stub, screenshots at those frames
(docs/09 9.2).

## 4. The medium from source

One build of L1 per stage from the one recording, on one instance (`U` = the unreal-ng checkout,
`R=$U/tools/verification/analysis/re_session.py`, `B` = the unreal-qt binary of `wt-zynaps128-stage1/scratch/bin`; muted, port
base 14850, stopped after):

```sh
python3 $R open --work work/stage2/c1 --ttd work/stage1/c1/session.ttd --model PENTAGON --port-base 14850 --ranges 5B00-FFFF --binary $B
python3 $R build --work work/stage2/c1 --from-frame 1870 --to-frame 2051 --into work/stage2/boot
python3 $R build --work work/stage2/c1 --from-frame 2051 --to-frame 2183 --into work/stage2/loader
python3 $R build --work work/stage2/c1 --from-frame 2182 --from-tinframe 53027 --to-frame 2838 --into work/stage2/intro
python3 $R build --work work/stage2/c1 --from-frame 2838 --to-frame 3302 --into work/stage2/load2
python3 $R build --work work/stage2/c1 --from-frame 3302 --to-frame 3314 --into work/stage2/glue
python3 $R build --work work/stage2/c1 --from-frame 3313 --from-tinframe 51573 --to-frame 13702 --into work/stage2/game
python3 $R stop --work work/stage2/c1
```

Each part is annotated in its `.ann` and written by `tools/part_mkasm.py` (kit/mkgame.py's pipeline on an image that
is not the game: the L1 basic blocks whose bytes equal the image's, widened by the static walk; an `@const` / `@isub`
names a game address the set-up writes inside block 2's range). `tools/mkasm_all.sh` writes all ten parts and
installs each only when it assembles to the original's bytes. The packer: `tools/hrust1.py check` on both packed
blocks first showed which rules give the original's tokens (block 2 all of them; block 1 all but one, kept in
`src/intro/block1.hints`); `pack --file NAME` adds the packer's TR-DOS tail. The intro's pictures:
`tools/res_formats.py export` once, then `build`.

The game (step 2, once the 48K case's annotations were complete): `src/game/game.ann` seeded from
`../zynaps/src/game/game.ann` by a one-off script (`work/stage2/game128/mkann.py`: the module below `$6800` dropped,
the 48K's evidence renamed "48K c2" and so on, the changed places and the leftovers' zeros described, an "On a 128K"
paragraph on every routine the set-up or the glue patches), then edited by hand. kit/mkgame.py reads `case.json`
(the image `$6800`-`$FFFF` from `work/parts/game-6800.bin`) and the L1 of `work/c1`, `work/r1`, `work/r2`: links to
`work/stage2/game/l1.json` and `work/stage2/stubs/r1`, `r2`. The resource plugins `tools/res_*.py` are the 48K case's,
copied. Then the generated references:

```sh
ln -s ../stage2/game/l1.json work/c1/l1.json; ln -s ../stage2/stubs/r1/l1.json work/r1/l1.json; ln -s ../stage2/stubs/r2/l1.json work/r2/l1.json
sh tools/mkgame.sh          # kit/mkgame.py: 519 entries, 49 modules, identical; installed beside the parts
python3 tools/res_preview.py
sh tools/mkasm_all.sh       # block 2 now includes build/obj/game.bin
python3 ../../kit/refdocs.py --case .
tools/build.sh      # build/Zynaps(2In1)(km).scl and .trd: identical to the originals, every part compared on the way
```

The signatures (`../../signatures/sources.json`, the five `games/zynaps-128` items, from the listings `tools/build.sh`
writes in `build/lst/`): the game's modules through `kit/sig_add.py ann` (41 the same pieces as already in the base,
`found_in` added: 40 of the 48K's modules and the title tune on `sound/beeper/steve-turner-two-voice/seen-zynaps`;
`controldata`, `playfield`, `scroll`, `menu`, `interrupts` new, the modules with the changed places; `playerdata`,
`tables`, `topcells` have no anchor), and four `lst` entries: `sound/ay-players/starkos/seen-zynaps-128`,
`sound/ay-players/zynaps-cpc/zx-port-2018` (the CPC-derived engine), `system/input/kempston-mouse/seen-zynaps-128`,
`packers/hrust/1/seen-zynaps-128` (the base's `packers/hrust/1/screen-depacker` is the self-relocating variant, not
the same bytes; `tools/sig/depacker-end.asm` gives the depacker an end label). Then `python3 ../../kit/sig_index.py`
and `--check`: ok, 119 entries.

The mouse: the game's start test reads bit 1 of `$FADF` (`src/game/setup.ann`, the patch at `$A74E`); on a real
Kempston mouse that is the left button (MAME `kempmouse.cpp`, ZEsarUX, ZX Next VHDL). The glue's counts (the engine
stepped twice an interrupt in play): `l1.json` of the `game` build, per instruction (docs/02 2.4).

The sound (docs/09 9.3-9.6): the SK10 song and the engine data decoded once to text, checked against the parts,
built by `tools/build_sound.sh` (`tools/mkasm_all.sh` then writes `src/sound/` too). The players simulated in
SkoolKit by `tools/sound_render.py` (its `witness` equals the recordings' RAM: STarKos after 385 frames, the engine
after 118), rendered against the CPC original's YM dump (cpc-power, `work/stage2/sound/cpc/`) and the CPC rip whose
engine is the same code moved by `$5000`:

```sh
python3 tools/sk10.py decode work/parts/starkos-8000.bin > src/res/music/sk10.txt
python3 tools/sk10.py check src/res/music/sk10.txt work/parts/starkos-8000.bin
python3 tools/sound_data.py decode work/parts/engine-data-de48.bin > src/res/sound/engine-data.txt
python3 tools/sound_data.py check src/res/sound/engine-data.txt work/parts/engine-data-de48.bin
sh tools/build_sound.sh
python3 tools/sound_render.py witness intro; python3 tools/sound_render.py witness game
python3 tools/sound_render.py notes game --frames 10304; python3 tools/sound_render.py notes "ym:$YM5"
python3 tools/sound_render.py wav game --frames 10304 --out work/stage2/sound/game-music-zx128.wav
python3 tools/sound_render.py chart --frames 1500 --out docs/img/sound-notes.png intro@1000000 intro "ym:$YM5" game
```

`YM5` = `work/stage2/sound/cpc/cpc-power/ym-unpacked/Zynaps (1987)(Hewson)(Dave Rogers)().ym5`. The emulator's own
check of the intro's pitch: the stage-1 `intro-tune.wav` (Pentagon) peaks at 459.6 Hz, the render at 465.8 Hz for
the 128K clock (1.75 / 1.7734).

The five stubs `c1` never ran (docs/09 9.2), witnessed in two bot recordings. A live instance like a capture's
(`tools/play_live.py`), the game's title with INF.LIVES and `$FFD7` = 1 saved from it (the TRD inserted with
`POST /disk/A/insert`: the snapshot holds no disk; `$FFD7` written into RAM page 0, not CPU space), the bot's input
script, then the capture:

```sh
python3 tools/play_live.py start --work work/stage2/stubs/live --binary $B
python3 tools/drive.py ... run:10 key:1:6 run:20 key:0:6 run:1000 key:space:6 run:400 save:work/stage2/stubs/title-inf.szx
#   PUT /api/v1/emulator/{id}/memory/ram/0/16343 {"hex":"01"}, then save work/stage2/stubs/title-inf-ffd7.szx
python3 tools/play_bot.py --work work/stage2/stubs/live --snapshot work/stage2/stubs/title-inf-ffd7.szx \
    --prefix work/stage2/stubs/inputs/start-1player.txt --frames 7000 --select 2,3,4 \
    --script work/stage2/stubs/inputs/bot-r1.txt --log work/stage2/stubs/inputs/bot-r1.tsv
python3 tools/play_live.py stop --work work/stage2/stubs/live
python3 $R capture --work work/stage2/stubs/r1 --snapshot work/stage2/stubs/title-inf-ffd7.szx --model PENTAGON \
    --inputs work/stage2/stubs/inputs/bot-r1.txt --port-base 14870 --binary $B --ranges 4000-FFFF
python3 tools/play_stubs.py --work work/stage2/stubs/r1 --out work/stage2/stubs/r1-stub-frames.txt
```

`r2` starts from `r1`'s frame 4400 (`time_travel seek`, `snapshot/save`: `r1-4400-homing.szx`) with
`play_bot.py --select 4 --lock --park 17,10 --frames 1000`, captured the same way. Each event's chain:
`time_travel find_last access=execute addr=... phys_page=2|4 all=true from_frame=F before_frame=F+1`. A bot run and
its capture agree until about frame 3000 only (key timing drifts, likely `run_frames` not stopping on frame edges):
each recording is consistent in itself, the frames in docs/09 are the recordings'.

The comparison with the 48K (`docs/img/compare/`, `docs/texts/differences.md`): two more recordings, `r48` (the
48K `ZYNAPS.TAP` from power-on) and `k128` (the TRD to the keyboard definition), their inputs in
`work/stage2/compare/inputs/`; each open on the instance, `tools/compare_shots.py` reads the screens at the chosen
frames (`memory_at`, exact), and `tools/fig_compare.py` draws the side-by-side figures from those bytes only.

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |
| The Kempston mouse's buttons are swapped in `core/src/emulator/io/mouse/mouse.cpp`: the left button is given on bit 0 of `$FADF` and the right on bit 1, while a real interface has left = bit 1, right = bit 0 (MAME `kempmouse.cpp`, ZEsarUX, ZX Next VHDL). On unreal-ng this game starts in mouse mode with the right button | open: to fix in unreal-ng separately | |

## 6. The game

## 7. Review
