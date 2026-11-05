# Zynaps: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`. The commands in full: `work/stage1/NOTES.md`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

Two media: the WoS perfect TZX (the reference) and a TAP. `tools/tzxblocks.py list` showed nine standard blocks
and an archive-info block naming the loader "Hewson Countdown II": no turbo, the protection must be in the code.
The TAP turned out to be a 1993 re-tape of the same bytes ([03](docs/03-build-and-load.md) 3.6).

## 1. One recording from power-on

`c1`: `re_session.py capture --record-load` on 48K, the TZX, 4000 frames after the load. The emulator's fast load
took the BASIC and the loader (ROM LD-BYTES) in 250 frames; the Hewson loader's blocks played at signal speed, so the
game starts at `c1` frame 12323. `re_session.py stages` gave the eight stages ([03](docs/03-build-and-load.md) 3.5),
`interrupts` the IM2 handler `$A9E4` of the title.

## 2. Static pass over the medium

- The BASIC (`tools/basic_list.py`): `CLEAR 32767`, the loader at `$FC00`, `USR 64512`.
- The loader: 19 plain bytes that XOR each byte with the next over `$FC13-$FE9E`. In Python:

  ```python
  b = bytearray(open('work/blocks/tzx4.bin', 'rb').read())
  for i in range(0x13, 0x29F):
      b[i] ^= b[i + 1]
  ```

  The plain code is the ROM's LD-BYTES with its edge routine hooked to drive a byte counter
  ([03](docs/03-build-and-load.md) 3.3).
- picy: a 9-byte header with three stream offsets; `tools/depack_picy.py` reproduces the screen.
- `sig_scan` over every block and image: nothing known (NOTES).

## 3. The stages and the packers

`tools/check_load.py` read `c1` at each stage's moment through the TTD session (`time_travel memory_at`) and
compared it with the static decode: zero differences except the counter digits on the screen. So
`work/images/static-entry.bin` is the game exactly as `$8000` is entered.

## 4. The medium from source

Stage 2 started from the medium, because every part of it could be proved without the game's names:

- `src/tape/basic.asm` writes block 2 from tokens and number macros; line 20's false length word (98) and its
  missing end of line are written as they are.
- `src/tape/loader.asm` is the loader in the clear, named from the 03 3.3 table; `tools/xorchain.py encrypt`
  applies the chain backwards from the plain byte after the range (`tape[i] = plain[i] ^ tape[i+1]`) and checks
  that the decryption gives the source again. The block's plain tail was compared with the 48K ROM: `$FEE9-$FEFF`
  is the ROM's `$0652-$0668` (SA-DATA) to the byte, `$FED5-$FEE8` matches nothing of the ROM longer than three
  bytes (left-over RAM of the mastering machine, never run: [03](docs/03-build-and-load.md) 3.3).
- picy: the guess "a byte equal to the one before it is always a repeat" made `tools/picy.py pack` give the tape's
  three streams exactly (3049 literals, 775 masks, 108 flags; `tools/picy.py check`), so the packer has no choice
  left to model. `src/tape/picy.asm` is the unpacker with the streams as `INCBIN`; the stage 1 table had the header
  words one byte early (they are at `$8004`, `$8006`, `$8008`, the border at `$800A`), fixed in 03.
- `tools/image.py` cuts the game image out of `orig/Zynaps.tzx.zip` (block 8 at `$61A8`), `case.json` names it for
  `kit/mkgame.py`; a first `mkgame.py` run with an empty `game.ann` already assembled to the image.
- `tools/tzx.py` writes the TZX from `src/tape/zynaps-tzx.txt` (version 1.10, the archive-info strings, the eight
  `$10` blocks with their headers' parameter 2 words and the pauses).
- The DRJ TAP: its `zynaps0.c` RLE turned out to be greedy too (every run of three or more is a token,
  `tools/rle_drj.py check`), so the second target cost two short sources (`src/tape/drj/`).

`tools/build.sh` builds both and compares them with the zips' files; it holds `build/.lock` while it runs, so two
builds never share `build/`.

## 5. Every level recorded

First look (stage 1): the disassembly from `$8000` gave the start-up, the main loop, the print routines (and so the
messages, `tools/texts.py`), the controls and the player records; `tools/drive.py` ran the menu by an input script
(`work/explore/menu/menu.txt`) to `play-start.szx`; `tools/bot.py` played level 1 honestly (275 points and a death
in 1500 frames), recorded as `c2`. The TAP's POKEs pointed at the lives and the kill routine, and next to the kill
the collision check reads `$FFD7`, which nothing writes: the developer switch Invulnerable.

- `tools/bot.py` (Kempston, reads the ship's record and the screen) played from `work/run/play-imm.szx` (play on
  level 1 with `Invulnerable` `$FFD7` = 1) for 100000 frames: its input script is `work/run/all.txt`, its log
  `work/run/all.tsv` (frame, lives, score, X, Y, deaths, level). It went through all twelve level slots and wrapped
  to the first (`work/run/levels-sheet.png`, a screen at each level's start; `work/run/shots/` every 250 frames).
- `r1`: `re_session.py capture --snapshot work/run/play-imm.szx --inputs work/run/all75k.txt --model 48K --ranges
  5B00-FFFF` on its own instance (port base 14110): 75001 frames with L1, TTD and a snapshot every 250 frames. The
  replay drifts from the bot's run by a few hundred frames a level but holds: read from `r1`'s snapshots (the player
  record `+6`, LevelOrder `$8003`), the level counter reaches every slot, with 0 deaths:

| Counter | Level | First seen (`r1` frame) | Score |
| ---: | ---: | ---: | ---: |
| 0 | 0 | 250 | 100 |
| 1 | 1 | 6500 | 8000 |
| 2 | 2 | 12750 | 19425 |
| 3 | 7 | 18500 | 26925 |
| 4 | 6 | 25000 | 34450 |
| 5 | 5 | 31250 | 46900 |
| 6 | 4 | 38500 | 52300 |
| 7 | 8 | 44000 | 63075 |
| 8 | 3 | 51500 | 68625 |
| 9 | 9 | 56250 | 73000 |
| 10 | 10 | 61500 | 81000 |
| 11 | 11 | 67250 | 92050 |

  The shuffle of this game is `0 1 2 7 6 5 4 8 3 9 10 11`. Each level's wave script runs to its `levelend`
  (CmdLevelEnd, 11 times in `r1`); the big enemies (BuildBigSprite `$8F0C`, kinds `$14` up) are built 6 times
  (frames 16855-66273); the bot's run wrapped back to level 0 at its frame 73600 with 100300 points.
- `case.json` reads both `c2` and `r1`: `r1` brought 31 code entries no other recording ran (the path ops, the
  checkpoint and level-end commands, LockableHandler, BigEnemyHandler, BuildBigSprite, LevelDone).

## 6. The source: six annotators and one merge

The image was cut into six ranges, each annotated by its own agent into a fragment (`work/ann/NN-*.ann`) with a
cross-reference of the addresses outside it (`NN-xref.txt`) and notes with the evidence (`NN-notes.md`); each
fragment was proved alone with `kit/mkgame.py --ann` (header + fragment: the bytes identical):

| Fragment | Range | Modules | Found |
| --- | --- | --- | --- |
| `05-f5` | `$61A8-$8515` | tilecopy ... texts | the level data byte by byte (paths, waves, scripts, scenery, shapes; `tools/res_levels.py`), the variables, the messages and the high scores (`tools/res_text.py`); LevelTable is `$6B2D` (the code adds 8 to `$6B25` first) |
| `10-f1` | `$8516-$90B4` | system ... sprites | the renderer: 18 rows of span nodes (NodePool `$F800`) drawn by a RET chain, the glyph cache `$C000-$DFFF` (four shifts), the tile set and its flip/mirror flags, the scenery coroutine on its own stack, the sprite strips |
| `20-f2` | `$90B5-$A0EA` | objgrid ... enemies | the hit grid, LaunchWave, the path bytecode, the ship, the weapon fields of the player record, the fuel (measured: a step per 16 frames, FuelOut at 0), `Invulnerable` measured |
| `30-f3` | `$A0EB-$AB12` | objects ... interrupts | the print language (codes 0-6, the split-bold ROM font, `$1B n` nested messages), the pods and the weapon pick-up, the menu raster, the keys, the high-score entry, the nested interrupt chain (TTD `c2` frames 300-316) |
| `40-f4` | `$AB13-$B72E`, `$FF01-$FFFE` | hud ... start, tunedata, topcells | EventDispatch, the wave script VM (all 12 scripts walked), checkpoints, the shuffle, pause, the effects, the title tune (`tools/res_tune.py`), the glyphs (`tools/res_font.py`) |
| `60-f6` | `$B72F-$FF00` | buffers ... tables | the sprites stored complemented and drawn as paper, the descriptors found by pointer search (POP-read images have no L1 reader), the copy's content, the record layouts, the RS-232 leftover at `$FDE8` (`tools/res_gfx.py`) |

The merge (`work/merge/merge.py`) concatenated the fragments, renamed the clashes (WaveScriptStep, PlayerSetup), and
put names on 28 addresses that `r1` made entries: PlayInterruptExit's `RET` returns into the pass the interrupt
stopped, and L1 counts such a return as a dispatch, so each of those points became an entry. The prose of the
fragments quoted test labels (`l_9954`) and got the final names. The chain steps were renamed ChainBuildColumn1-3
(they call BuildColumn `$896D`, not a strip drawer). Then `kit/mkgame.py --install` gave 541 entries in 50 modules,
no auto labels, the bytes identical; `tools/build.sh` gave both tapes identical.

Resources: `tools/res_effects.py` was added for the six sound effects; `tools/res_formats.py check` proves the
eleven editable files both ways. `tools/memmap.py` draws the map from `tools/memmap.txt`; `kit/refdocs.py` wrote
docs 11 and 12.

Signatures (`signatures/sources.json`, the four Zynaps additions; metadata in `work/sig/*.json`):

- `sound/beeper/steve-turner-two-voice/seen-zynaps`: TitleTune (105 bytes; the `tune` module is its `found_in`);
- `packers/picy/seen-zynaps/depacker`: the picy unpacker (157 bytes; the header's stream offsets and border masked);
- `tape/loaders/hewson-countdown-2/decrypted`: the loader after its XOR chain, `Decrypt` to `DecryptEnd` (671
  bytes; the countdown and header state masked);
- `programs/games/zynaps/<module>`: 46 modules (tilecopy, gameentry and playerdata skipped: space, 3 bytes, no
  anchor; tune went to the beeper entry).

`kit/sig_index.py --check`: 110 entries ok; `kit/sig_index.py` rewrote `index.json` and `INDEX.md`.

## 7. Tool gaps

| Gap | Effect here | Done |
| --- | --- | --- |
| L1 takes an interrupt return that does not come back to the interrupted call (PlayInterrupt's nested chain) as a dispatch to a routine entry | 28 entries inside routines (labels such as `RotateLineStore`) | named in `game.ann`; an unreal-ng L1 gap, not fixed in this stage (no unreal-ng build was allowed) |
| `kit/mkgame.py` reads every `work/*/l1.json` for entries | cannot keep a recording for its coverage while ignoring its entries | none (the kit is shared) |
| `res_formats.py` finds a file's kind by its suffix | two plugins with the same suffix would shadow each other | each plugin has its own suffix |

## 8. Review

Open (stage 3): the weapons were never taken in any recording (the bot does not hold fire on a pod), so the pod
actions and the plasma, homing missile and seeker handlers are read from the code and the tables only; the four
unused strip entries `$F704-$F733`; the 36 bytes `$F108-$F12B`; the fields `+2/+3`, `+9`, `+$0A`, `+$0C` of the
sprite descriptors; StarsSwitch `$8884` has no caller.
