# Elite: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number. The unreal-ng
binary is `scratch/wt-nezs-stage1`'s agent build (`work/env.sh`): the default `cmake-build-agent-release` binary of
2026-10-24 answers "Unknown tool: analysis".

## 0. The medium

Four files from the owner (`orig/`): the WoS TZX archive with both sides (Side A "With Krait ship", Side B the
Adder), a second TZX dump, the cracked `ELITE48.TAP` and the instructions. The ZXDB extras (the Lenslok
instructions PDF, the keyboard overlay, the novella, the inlay scans) came from spectrumcomputing.co.uk into
`work/extras/`.

- `tools/tzxblocks.py list`: two ROM blocks (a BASIC "E L I T E"), a "Softlock Group" (one turbo block with short
  timings, then 29 pure-data blocks with no pilot), two headerless ROM blocks. The protection is on the tape.
- `cmpblocks.py` (work): Side A and B differ in four data blocks; `Elite - 48k.tzx` is Side B's data byte for byte;
  `ELITE48.TAP` has the md5 of `elite-skoolkit`'s `tape/elite.tap`, so that disassembly describes the cracked
  release, not the protected one.

## 1. One recording from power-on

`c0`: `re_session.py capture --record-load` on 48K, Side A, 1500 frames with no input after the load (fast
LD-BYTES trap on, the default). `re_session.py stages` named the entries `$5D93` (frame 250), `$5DD0` (256),
`$FF00`, `$5B00` and, at frame 11186, the Lenslok code at `$C213`. The screen at frame 1500 is the Lenslok size
screen (`work/shots/c0-1500.png`).

A second capture with ENTER pressed on that screen (`work/lp`, trap on) changed nothing: LAST_K, FLAGS and the
FRAMES counter stood still for 400 frames. `time_travel seek` to frame 11800 and `inspect_state`: PC = `$C67D`, the
key loop polling FLAGS bit 5, IM 1, **IFF1 = 0**. `reverse_continue` to `$C213`: entered with IFF1 = 0;
`reverse_continue` to `$0802` and `$D06C`: the two ROM loads of `$D05F` returned within 4000 T-states each;
`reverse_continue` to `$054F` (the ROM's EI in SA/LD-RET): never reached. The fast-load trap skips that EI
(section 5). `tools/capture_real_rom.py` wraps `re_session.py capture` and switches the `fasttape` feature off
(`PUT /api/v1/emulator/{id}/feature/fasttape`) before the load: the next capture's Lenslok screen took ENTER at
once.

`c1` (trap off, the ROM loads at signal speed): the tape ends at frame 15700; `tests/inputs/c1-lenslok.txt` then
presses ENTER, types the code and leaves the title running.

## 2. Static pass over the medium

- The BASIC (`tools/basic_list.py`): `basic_list` prints the five-byte values beside the digits; three of them
  differ from the text (03 3.2). The first listing read the program from the block's flag byte, one byte early, and
  showed line 65280; the source build (section 4) caught it, the program is line 0. `RANDOMIZE USR (PEEK 23627+256*PEEK 23628)` enters the code after the program.
- `tools/softlock.py`: the turbo block's first bytes did not look like a screen until each byte was bit-reversed
  (the loader's `RR L`, 03 3.4); then the first 6912 bytes rendered as the loading screen
  (`tools/fig_loading.py`). The rest of the stream parsed as 4-byte headers (length, address) and data with one
  check byte each, the XOR of every chunk 0: 14 chunks on both sides.
- Three chunk addresses looked wrong (the game at `$9B00` while the decryptor's range ends at `$D0A8`, a 5-byte
  chunk into the attributes). The 2-byte chunks at `$5B1C` explained them: they patch the reader between chunks
  (03 3.5), confirmed against `c0`'s memory at frames 5000 and 11110.

## 3. The stages and the packers

- The stub at `$5D93`: disassembled from `c0` frame 250 (`work/dis.sh`, sna2skool over a `memory_at` dump). Its
  key is the sum of `$4000-$5BFF`, so the screen the BASIC leaves is part of the key. Frame 256 shows the decrypted
  code: LD-BYTES copied from the ROM to `$FF00` and 28 bytes patched.
- The loader `$FF00` (frame 1000) set against the ROM's `$0556` line by line (03 3.4 table).
- The decryptor: `analysis trace` over frames 11100-11186 (`work/c0/traces/decrypt.uatr`) showed the loop's reads:
  the source `$D0A8` downwards, the key bytes `$5AFF` downwards through the ROM. The chunk of TZX blocks 20+21 puts
  `LD IY,$2E6D` into the reader: the second key.
- The end of the decryptor: `find_last` on `$5B47` gave the last write by PC `$5B47` itself (the self-overwriting
  LDIR), and `reverse_continue` to `$D05F` the RET it ends in (frame 11186 t=27559).

- The static decode: `tools/image.py --check` runs steps 1-5 of 03 (the stream with the reader's patches, the
  decryption keyed on the screen and the ROM, the ROM blocks, the copy and the squares) with no emulator. It equals
  `c1`'s memory at the game's entry over `$5B00-$FFA7`, except 18 system-variable bytes the ROM writes at run time.

## 3a. The Lenslok

- Entering it at all needed `c1` with the trap off (section 5). On the size screen `c1` presses ENTER, then the code
  screen appears (frames 15866-15891 drawing, 15900 complete; `work/lenslok/*.scr` are `memory_at $4000` of each).
- The answer, first from memory: `memory_at` `$C799` at frame 15900 holds the code "si". This is enough to pass,
  but it explains nothing, so the code was read routine by routine (lenslok.md 4).
- The seed: `$C297-$C29D` stores the two `LD A,R` at `$C784`. `memory_at` `$C784` on the code screen gives
  `$FE81`. `tools/lenslok_answer.py` models Rand, SetMarks, PickChar and PickCode. With the excluded set as the image
  holds it ("TLWMIYfmwtzl"), its first answer was "2H". `memory_at` `$C7A9` on the code screen showed the first four
  bytes of the set overwritten. Reading `GlyphGather` explained why: it copies 8 - r bytes per row into a 4-byte
  buffer. With "IYfmwtzl" the model gives "si" in 10 draws, as the game did.
- The picture: `tools/lenslok.py draw` against frame 15900 differed by 34 pixels, all in the bottom row of the
  second character: the same overrun, read from the other side (8 - r bytes per row, so row 7 fetches one byte).
  After that, 0 pixels differ (`docs/img/lenslok/model.png`).
- R bit 7: the crack's loader sets it (`OR $80`, below), which pointed back at the decryptor's `LD R,$FF`. It is not
  a decoy: it fixes bit 7 of the Lenslok's seed (03 3.6 corrected).
- The instruction sheet (ZXDB PDF) has two printings. The second describes the second round of three attempts that
  `$C78A` implements.

- Every code (lenslok.md 5). There is no table, so the challenges were enumerated rather than sampled.
  `tools/lenslok_sim.py` runs the game's own `$C2A0-$C2A8` in skoolkit's Z80 simulator, starting from `c1`'s memory
  at `$C2A0` (frame 15868, `memory_at` with the tinframe that `reverse_continue` gave). The simulated screen for seed
  `$FE81` equals frame 15900: 798 pixels, 0 differ. The enumeration walks every state byte and every state a previous
  code leaves. It found 951 states, 121 856 challenges and 475 codes, 96 of which a first attempt can give; 52 more
  would need R bit 7 clear. The first single-process run was too slow under load (a new Simulator per call), so it
  now keeps one Simulator and maps each BFS level over a Pool.
- Codes never seen: I, Y, f, l, m, t, w (the excluded set the overrun leaves), and x. x is a lower-case candidate in
  only four generator states, and in each the next `Rand(3)` picks another candidate.
- Read-back check (`lenslok_sim.py check`): 122 of 128 first attempts plus 13 of 13 live ones read exactly. The 6
  others end in g or q. Row 7 of the second character repeats row 6, so "Sg" and "Sq" draw identical pixels
  (`draw(b'Sg') == draw(b'Sq')`). 10 of the 475 codes are such a coin toss for the player. A first check that matched
  rows 0-6 only had flagged 9; matching all 8 rows as drawn left these 6.
- Real challenges: `tools/lenslok_live.py` branches `c1` at frame 15760 (`time_travel seek`, then `resume`, which
  makes the history live; without it `run_frames` only replays `c1`'s own ENTER and every seed came out `$FE81`). One
  frame later moves R by `$24`. "99" is always wrong, since `Rand(9)` never gives 9. The right answer is computed by
  the simulator from the memory saved at `$C2A0`. Three runs gave 13 attempts: two rounds of wrong answers ending in
  the reset, and two accepted computed answers. A first try lost sync: `run_until_pc` says "Ran until PC." in its text
  even when the budget runs out (section 5).

## 3b. The crack

- `ELITE48.TAP`: the BASIC loads 37 bytes at `$FFA9`. The loader, read with `work/dis.sh` from the block, loads
  `$4000-$FFA8`, tests A = `$DC`, writes `$18` to `$C22E` and jumps to `$D079`.
- Its 49065 bytes against `tools/image.py`'s steps 1-4 (no kickoff copy) of Side A: 0 bytes differ over
  `$4000-$FFA7`. The cracker saved memory at `$D079`.
- The first `k1` (trap off, 6770 frames) ended mid-load at `$9CD9`. The fast trap would not help: it declined the
  block, because its payload is 49066 bytes while DE is 49065 (`tapefastload.cpp`, row 8: exact length). This is the
  trap behaving right. It led to the parity trick: A = `$DC` is the XOR of everything read, and the real parity byte
  is never read (lenslok.md 7).
- `k1` with 15500 load frames: the load ends at 13790, then three code screens time out and the game starts at
  16235 with nothing typed (the frame table in lenslok.md 7).

## 4. The medium from source

Side A is rebuilt from sources, byte for byte: `tools/build.sh` ends with `build: Elite-SideA.tzx identical to
orig/Elite.tzx.zip's Side A`. The order it was done in:

1. The BASIC and the stub in clear as `src/tape/basic.asm`, compared with the decrypted block 3 from
   `tools/softlock.py`; the five-byte values went in as a `NUM` macro so LIST shows the digits the tape shows.
2. The Softlock code pieces as `src/tape/softlock.asm`, each `SAVEBIN` compared with its chunk.
3. The block list `src/tape/elite-tzx.txt` and `tools/mktape.py`, which encrypts the stub with `$CA4E` and the
   chunks over `$6049-$D0A8` with the loading screen and the ROM. The first try differed in the chunks only; a diff
   of the plain memory against `game.bin` gave the three differences 03 3.10 lists (the Lenslok at `$C000`, zeros at
   `$BE00`, 1096 bytes at `$5C00`), and the decrypt range moved from `$605F` to `$6049`.
4. The filler chunks: diffed against zeros they held the same 43 bytes at `$F300`, the plain loader; the two ROM
   copies (`rom:0000:48`, `rom:0000:1000`) diffed against unreal-ng's `48.rom`.
5. The Lenslok as its own part (`src/lenslok/lenslok.json`, `mkgame.py --part`): the image at the pre-kickoff stage
   (`tools/image.py --stage prekick`), since the kickoff overwrites `$C000-$C7FF`.

Side B is rebuilt too (`build: Elite-SideB.tzx identical`): `tools/sideb.py export` diffed the Side B image
(`tools/image.py --side B`) against Side A's and found three places only (the blueprints `$6180-$6FF1` with the
Adder, slot 0's word at `$606B`, the mastering sysvars), so `src/sideb/sideb.asm` lays them over Side A's
`game.bin` and `src/sideb/elite-tzx-b.txt` lists Side B's blocks. `b1` loaded the original Side B in the emulator;
`tools/b1_live.py` answered the Lenslok from the game's own code in the simulator and compared the memory at the
entry `$70E0` with the build: 18 bytes differ, all ROM system variables (03 3.12).

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Repro | Fix | unreal-ng commit |
| --- | --- | --- | --- |
| The fast LD-BYTES trap leaves IFF1 as it was; the ROM's SA/LD-RET always runs `EI` at `$054F`. A loader that calls LD-BYTES / LD-BLOCK with the interrupts off (Softlock's `$D05F`) continues with them off, so Elite's Lenslok screen never sees a key and its HALT never returns (03 3.9) | `re_session.py capture --record-load --media "Elite - 48k - Side A.tzx" --load-frames 17500` with `--inputs` pressing ENTER 100 frames after the load: LAST_K, FLAGS, FRAMES constant; `inspect_state` at PC `$C67D` says IFF1 = 0. With `fasttape` off (`tools/capture_real_rom.py`) the same input works | not fixed here (the case rebuilds nothing in unreal-ng): the trap should set IFF1 = IFF2 = 1 on return, as `$054F` does; worked around with `tools/capture_real_rom.py` | |
| `re_session.py` takes ports base..base+500 (WebAPI, CLI +100, MCP +200, GDB +300, DeZog +400, ZRCP +500): no port base keeps all of them inside a 100-port window such as 18300-18399 | `re_session.py capture --port-base 18300` listens on 18300, 18400, 18500, 18600, 18700, 18800 | not fixed; the case uses `--port-base 18300` (WebAPI 18300) | |
| The step-back action stops at a fast-load return: `step_back_instruction` from `$D07C` repeats `$D079` forever (the trap's synthetic instruction has no previous instruction to step to) | `c0` (trap on): seek to frame 11186 t=68114, `step_back_instruction` x 12: PC `$D07C`, `$D07B`, `$D07A`, then `$D079` eleven times | not fixed; `reverse_continue` with `pcs` reaches the earlier code | |
| `control_execution run_until_pc` answers "Ran until PC. PC=..." in its text whether or not the target was reached; only `structuredContent.hit` (false, "T-state budget exhausted before reaching target") tells. An agent that reads only the text takes a miss for a hit | `run_until_pc` with `pc` `0x1234` and `max_tstates` 1000 on any running machine: the text starts "Ran until PC." with PC elsewhere | not fixed; `tools/lenslok_live.py` reads `hit` | |

## 6. The game

### 6.1 The recordings

The game recordings start from one snapshot, `work/snaps/title-A.szx`: the title of `c1`, after the Lenslok was
answered (so no recording of the game patches or skips it). `re_session.py capture` with port bases in 18300-18399
(WebAPI 18300 for `f1`, 18320 for `w1`) ran each input script of `tests/inputs/` and kept the TTD session, L1 and L2:

| Recording | Frames | L1 | What it covers |
| --- | ---: | --- | --- |
| `d1` | 2710 | 402 routines, 17.8 M instructions | the docked screens L, K, P, I, O, the launch |
| `f1` | 4856 | 403 routines, 31.3 M instructions | the launch, the station, the jump to Diso, empty space, the laser |
| `w1` | 6691 | 431 routines, 44.5 M instructions | pause F, the misjump, four Thargoids, the death, the title again |

`w1` needed the pause option F: a normal jump misjumps once in 256 (StarSeed `$F9`), and the code showed bit 6 of
Options forcing it (docs 05 5.8). Snapshots every 250 frames went to `work/<rec>/snapshots/`; `tools/timeline.py`
sampled the view, the speed, witch space, the condition and the slots every 10 frames from the live instance
(`work/prof/<rec>-timeline.json`).

Windows of interest were traced with `analysis trace` (`work/<rec>/traces/F_T-F_T.uatr`: every instruction, read,
write and port access with its T-state) and cut down with `tools/trace_cut.py` for the animations. `tools/eprof.py`
turns a trace into a per-routine profile (`work/prof/*.json`); `tools/rtscenes.py` names the windows as scenes.

### 6.2 The source

The image (`tools/image.py`, the memory at the game's entry `$70E0` decoded from the tape alone) was annotated in 26
parts by module (`work/ann/parts/00-head.ann` to `25-keyboard.ann`), concatenated into `src/game/game.ann` by
`work/rebuild.sh`, which then runs `kit/mkgame.py --install`, `kit/refdocs.py` (docs 11 and 12), `tools/build.sh` and
`kit/check_docs.py`. The entries come from the L1 of `d1`, `f1` and `w1`; the routines no recording ran were walked
statically from their callers. The result: 669 routines and 374 data entries in 26 modules, no auto labels, Side A
identical. The modules were named for what they hold once the code was understood (`work/rename_modules.py`, one-off:
`screen` became `backbuffer`, `cross` `chartcursor`, `actions` `combat`, `ui` `menuhelpers`, and so on).

- **`@isub`** (25): constants whose bytes look like addresses, written so the kit does not name them: `LD HL,$A000`
  in the circle projection (a distance limit), `LD HL,$8040` in the line clipper, `LD HL,$7FFF` a position clamp,
  `LD DE,$C00C` in SoundArmArrive (the pitch `$C0` and 12 passes, which the kit first wrote `BackBuffer+$000C`);
  and operands that need an expression: `LD SP,BackBuffer+$1000` is ClearView's stack fill
  ([06](docs/06-rendering.md) 6.3), `LD IY,ShipSlots-$27` starts a slot walk one slot before the first.
- **Resources** (`src/res/`, `tools/res_formats.py`): the font as a PNG, the 19 blueprints as text
  (`ships.txt`, the vertices, edges and faces), the compass dots, the loading screen, the token text
  (`tokens.txt`) and the mastering machine's 1096 bytes.
- **The market** was checked against the snapshots, not only read: `tools/galaxy.py --market` reproduces Diso's 17
  prices and stocks at `f1` 2500 exactly, and showed two things the first reading missed: the stock for a positive
  factor is base + f - product - 1 (`INC A / NEG`), and NewGame NOPs the stock store at `$E1AE`, so Lave's stock is
  the commander record's.
- **The rating** loop was read twice: the first table put each threshold in the rank above; `CP (HL) / JR NC` stops
  at the first threshold at or above the byte, so each belongs to the rank below (docs 10 10.6).

### 6.3 The figures and the measurements

| Tool | Figures | From |
| --- | --- | --- |
| `tools/writers_map.py` (the kit's, larger text), `fig_writers_dash.py` | which routine wrote each screen byte (`:screen` buffer views for the back buffer `$C000`) | `f1` 1504-1510, `w1` 3490-3500 |
| `tools/memanim.py` (the kit's, larger text), `memanim_f1.sh` | memory over two station passes, every half frame | `f1` 1504-1515, its TTD session |
| `kit/routine_anim.py` | a routine drawing, instruction by instruction (ClearView, a ship, the planet, the stardust, the tunnel) | short trace cuts of `f1`, `d1`, `w1` |
| `tools/fig_objects.py`, `fig_slot.py` | the eight slots over a window; one slot's 39 bytes frame by frame | `w1` 3470-3620 |
| `tools/fig_font.py`, `fig_pages.py`, `tokens.py` | the font sheet; recorded pages; both token sets as text | the image, `d1` |
| `tools/fig_sound.py` | every OUT to `$FE` as pitch and waveform; `--timeline`: the sound's T inside and outside the interrupt, the lost interrupts | `f1`, `w1` traces |
| `tools/fig_galaxy.py`, `fig_course.py`, `galaxy.py --describe` | galaxy 1 and Lave's range; the three recordings as games; a system's data and description | the image, the timelines, L1 |
| `tools/elitebot.py`, `tests/inputs/*.py` | the scenes: a bot that presses keys and reads memory, never writes it; each plan records `work/<rec>` | the title snapshot, the commander tapes |
| `tools/commander_tape.py`, `tape_from_trace.py` | a saved commander read back from the speaker writes; the edited fixtures (`rich.tap`, `k2.tap`, ...) | `t1`, `gx` |
| `tools/l1runs.py` | which routines a recording entered, from its L1 (a routine reached by JP shows none) | the L1s |
| `tools/grab_slots.py`, `fig_slots_anim.py` | the eight slots (`$6048`, 312 bytes) every few frames; the fight animated from above | `k2` 2484-4248 |
| `tools/fig_design.py`, `fig_scenes.py` | the recorded scenes as GIFs (launch, flight, fight, dock, scoop, nova, explosion), the dashboard, the reaction to a key; the commander save as a tape signal | all recordings |
| `tools/fig_3d.py`, `shipsim.py`, `fig_ships_anim.py` | the 3D engine: the game's own drawing code in a simulator, the gallery, each ship alone for [the ships](docs/ships.md), hidden lines, the approach, the pipeline, formats, drift, octants | the image, `d1` |
| `tools/fig_scene_strip.py`, `fig_scene_strips.sh` | each recorded scene as a strip of its own screens, for [scenes](docs/scenes.md) | the scene recordings |
| `tools/fig_sound_anim.py`, `fig_sound_all.sh` | each beeper effect as an animation in step with the frames: the screen, the speaker bit, the pitch track | `w1`, `k2`, `f1` traces |
| `tools/fig_galaxies.py`, `fig_galaxy_md.py` | the eight galaxies, the seeds, the twist, the names, the histograms | the image |
| `tools/fig_market.py`, `fig_phases.py` | the market over the fluctuation byte; one station pass animated over the back buffer and the screen | the image, `f1` 1500-1600 |
| `tools/bbc_compare.py`, `fig_bbc_ships.py`, `fig_bbc_compare.py` | the BBC comparison table by table (the disc build's `IF _*_DISC` variants resolved, the splinter's and the Thargon's borrowed edges followed); the same ship from both blueprints; side by side: the header formats, the galaxy, the market, the dashboard (from the cassette's `P.DIALS.bin`), the docking test, the kills | `work/bbc` (Moxon's sources), `d1`, `t1`, `f1` |
| `tools/fig_sound.py --spectrogram`, `fig_sides.py` | the effects as spectrograms; the two sides' titles | `w1`, `k2` traces; `c1`, `b1` |
| `tools/fig_rt_*.py` | the runtime analysis: scenes, frames, the pipeline, the generators, the beam, the flame graphs | the traces |

What the measurements found that the code alone did not tell:

- **Two sound players at once.** SoundGameOver runs with the interrupts on through SoundPlay while the interrupt's
  SoundTick plays the requests; at `w1` 4308 a stale SoundBit XOR set the laser bit again (docs 09 9.6).
- **The laser costs 2.8 frames a shot** inside the interrupt (SoundSweep, E 253 then 247), and the fight lost 12
  interrupts to it and 5 to ClearView's DI at `$8080`, 11 frames apart (docs 09 9.9, runtime analysis 8).
- **Slot 7** has two users: the title's turning ship and the player's missile in flight; the code names it directly
  (docs 07 7.1).
- **The course condition**: Condition `$7104` sampled at a frame's start reads green while the screen shows red
  (`w1` 3000), because the pass recomputes it each time; the course figure leaves the condition out (docs 10 10.9).

### 6.4 Kit changes (in `kit/`, every other case rebuilt identical)

- `kit/routine_anim.py`, `kit/writers_map.py`, `kit/kitlib.py`: a `:screen` buffer order (whole thirds in the
  screen's line order, 32 bytes across) for Elite's back buffer.
- `kit/mkgame.py`, `kit/sig_add.py`: `@inline $ADDR N`, a routine that reads exactly N bytes after its CALL (the
  walk goes on after them); `docs/ann-format.md` and `kit/README.md` describe both.

### 6.5 Signatures

`signatures/sources.json` gained four additions, `kit/sig_index.py --check` says ok (213 entries):

- `protection/softlock/seen-elite/stub`: the clear head of the stub, `Stub` to `StubTail` (61 bytes);
- `protection/softlock/seen-elite/decryptor`: `Decrypt` to `DecryptEnd` (73 bytes, 9 masked);
- `programs/games/elite/<module>`: the 26 modules of the game;
- `programs/games/elite/lenslok-check`: the Lenslok check (`src/lenslok/lenslok.json`, 2048 bytes).

## 7. Review

What stays open, each named in its document:

- **No recording traded, docked, killed, scooped, fired a missile, used the E.C.M., the energy bomb or the escape
  pod, saved or loaded a commander, jumped galaxy or reached a mission**, and none used a joystick: those rules are
  known from the code only (docs 01 1.11, 05 5.9, 07, 10 10.4-10.8). A recording that docks and trades would close
  the largest share.
- **The station passes of about 450k T** in `f1` 1500-1600 (four of sixteen) were not taken apart (docs 04 4.5).
- **The BBC comparison** rests on bbcelite.com's descriptions; the two codes were not compared line by line (the
  site timed out when the market's stock formula was to be checked).
- **Side B** (the Adder) is not rebuilt: 3600 bytes differ, mostly the blueprint table (docs 03 3.10).
- **The unreal-ng gaps** of section 5 are reported, not fixed: the case rebuilds nothing in unreal-ng.

The references were used for cross-checks only, never as a source of bytes or names:

| Reference | Commit | Used for |
| --- | --- | --- |
| [elite-skoolkit](https://github.com/Rasmus-M/elite-skoolkit) (Rasmus M) | `66ee08e` | the cracked tape's md5 (the same `ELITE48.TAP`); its disassembly is of the crack, not of Side A |
| [zx-elite](https://github.com/ataribaby42/zx-elite) (ataribaby42) | `1eb6b82` | the ship record's layout (DATA-STRUCTURES), the laser rates (ROUTINE-CHECKS), the commander record |
| [EliteNext](https://github.com/TinfoilAsteroid/EliteNext) (TinfoilAsteroid) | `82000cd` | a ZX Next re-implementation: read for the naming of the BBC routines, nothing taken |
| [bbcelite.com](https://www.bbcelite.com) (Mark Moxon) | | the BBC game's galaxy, market and rating rules, for comparison |

DeadlyKom's Elite is Elite 3, a different game, and was not used.
