# Nether Earth GS: walkthrough

How the reverse was done, step by step, and which command or recording answered each question. Terms:
[docs/README.md](docs/README.md). Standard: [GUIDE.md](../../GUIDE.md).

The case was done in two stages by agents:

- **Stage 1** (one agent, committed 2026-11-05): the media, the load, the GS side, the sound triggers; what the game shares with
  [Nether Earth](../nether-earth/WALKTHROUGH.md) (NE). Committed as stage 1.
- **Stage 2** (2026-11-05, a lead and three forks): the full own source of every part of the three media, bit for
  bit, the resources in editable form, the screenshots against NE, the texts, the documents. The owner's rule for a
  derived case: the game is reversed in full on its own (its own `game.ann`, every routine named and described, true
  for this game), never "NE's source plus patches".

Each agent's log is in `work/` (local): `work/stage1/NOTES.md`, `work/stage2/NOTES-ld.md` (loaders, drivers, media),
`work/stage2/NOTES-trd.md` (the TRD extras), `work/stage2/NOTES-shots.md` (the figures).

`C` = this case, `R` = the repository, `U` = an unreal-ng checkout built with `tools/build/build.sh unreal-qt`
(the stages ran a worktree detached at github/master `e3d341d38`; `tools/gs_session.py` takes the checkout from
`UNREAL_NG`, default `/Volumes/TB4-4Tb/Projects/Test/unreal-ng`). Port base 12340 (WebAPI 12340, CLI 12440, MCP 12540, GDB 12640, DeZog 12740,
ZRCP 12840): none of them hits 10000. Every instance muted at launch and stopped after use; audio only to files.

Tools written for the case (all in `C/tools/`): `disk_files.py` (SCL / TRD catalogue and files), `basic_list.py`
(BASIC listing through nether-earth-editor's `zxbasic.detok_line`, read-only), `byte_diff.py` (differing runs of two
images), `sound_calls.py` (every call of the sound with its id and the GS effect it ends in), `gs_session.py` (a live
instance: launch, steps, stop; the GS port trace, the card RAM, audio to files).

## 1. Stage 1: the media, statically

| Command | Proved |
| --- | --- |
| `md5 orig/*`, `shasum orig/*` | the hashes of the brief (zip `b5da07ec...`, TRD `b6e5fe10...`, TAP `0ef2b5a6...`); SHA-1 zip `9c4f84b7...`, TRD `63a0fea7...`, TAP `245bbe48...` |
| `tools/disk_files.py work/media/scl/NE_GS_TZ.SCL --out work/media/scl/files` (`scl-catalogue.txt`) | 25 files; `neart001` declares 39536 bytes at `$6590` (155 sectors = 39680: the brief's 39680 is the sector count), so it ends at `$FFFF` |
| the same on the TRD (`trd-catalogue.txt`) | the SCL's 25 files plus `boot` (BASIC 172 bytes, 13 sectors), `Neart481` (BASIC 572 bytes, 171 sectors), `Neart482` (BASIC 116 bytes, 112 sectors); label `n-earth`, 28 files, 619 free sectors. Every `neart*` file equal to the SCL's (the BASIC `neart GS` differs only past its 67 bytes: the TRD keeps the autostart line 10 in the sector tail) |
| `tools/basic_list.py "work/media/scl/files/neart GS.B" 67` | `CLEAR 24999`, `RANDOMIZE USR 15619: REM : LOAD "neart022" CODE`, `RANDOMIZE USR 25000`: the loader `neart022` (865 bytes at `$61A8`) does the rest |
| `tools/basic_list.py work/media/trd/files/boot.B 172` and `strings` | `boot`: a code line (clear the screen, load 20 sectors at `$61A8` after itself, run them) and the text "HRUM v3.5 by Dmitry Pyankov ... 09.01.97": a HRUM-packed boot menu, not part of the game |
| the same on `Neart481.B`, `Neart482.B` | `Neart481`: a loader in a REM that reads its own tail into banks 0 (`$7530`), 6, 3, 4, 1 (`$C000`) and 0 (`$61A8`), then `OUT 32765` 19 / 22 / 16 with `USR 57800`, `USR 65004`, `USR 24110` and `USR 42496` (= `$A600`, NE's `Start`): a separate 128K build of Nether Earth, not the GS one. `Neart482`: "10.12.95 KIDSON OF RAPEWARE CORP. PRESENTS NEW INTRO FOR NEW PROG'S", "priwet wsem poklonnikam ... NETHER EARTH": an intro |
| a MOD header parse of `neart002..006` concatenated (`work/media/mod-concat.bin`) | one ProTracker module, `M.K.`, "_desert dream vol.2", 31 samples (26 used), 36 positions, 29 patterns; the size the header implies is 138070 bytes = exactly 4 x 32768 + 6998: the five files are the whole module and nothing else |
| byte statistics of `neart007..020`, `023` | 8-bit unsigned PCM (values around `$80`): the effect samples |
| `z80dasm` of `neart022` at `$61A8` | the loader: the GS protocol in [03](docs/03-build-and-load.md) |
| `z80dasm` of `neart021` at `$C000` | the GS sound driver: game sound id to GS effect, `#40` / `#39` |
| `kit/sig_scan.py work/media/scl/files/neart001.C --base 6590 --all --out stage1/sig-neart001.json` (table `sig-neart001.txt`) | exact: NE font, start, robotmenu, gameturn, ship, world, bases, level, mainmenu, view, screen, controls, print, tables; ANE's viewtail; candidates: sprites (61 bytes differ), music (21), construction (18), enemy (18), interrupts (37) |
| `advanced-nether-earth/tools/ne_match.py --image work/media/scl/files/neart001.C@6590:file --out stage1/match-neart001.tsv --summary` (read-only use of ANE's tool) | of NE's 563 entries 542 same at the same address, 3 changed, 12 fill, 6 absent; nothing moved: the game is NE's image at NE's addresses |
| `tools/byte_diff.py work/media/scl/files/neart001.C@6590 nether-earth/work/mkgame/original.bin@0000 --from 6590 --to D7D3 --gap 8` (`byte-diff-ne.txt`) | 159 bytes differ in NE's code and data, in 10 runs: `$A569-$A5A8` (new code in NE's spare zeros), `NuclearRumble`, the beeper `OUT`s of `LeadStep` / `BassStep` / `DrumStep` turned to `NOP`s, `ConstructionMenu`'s first instruction, `Beep`, `SoundEffect` |
| `tools/sound_calls.py work/tmp/neart001-64k.bin work/media/scl/files/neart021.C` (`sound-calls.txt`) | every call of the sound: 22 call sites, their ids, the GS effect each one plays (table in [09](docs/09-sound.md)) |
| the names table of the loader at `$63E0-$64AE` | the loader loads `neart019` where the 401-byte effect 11 should come from `neart017` (`$6273`: HL = `$648B` = "neart019C", DE = `$0191`): effect 11 is the first 401 bytes of `neart019`, and `neart017` is never read on disk |
| `kit/tapblocks.py list` on the TAP (`tap-blocks.txt`), `tapblocks.py TAP N OUT` (`work/media/tap/blkNN.bin`), `cmp` with the SCL files | 50 blocks: a new BASIC "NetherE GS" (961 bytes), then the SCL's files as standard blocks. Equal to the SCL: `neart000`, `002-020`, `023`. Changed: the loader `neart0222` (91 bytes), the driver `neart021` (248 -> 271 bytes), the game `neart001` (4 bytes) |
| `tools/basic_list.py work/media/tap/blk01.bin 961` | Hood's BASIC: "Conversion from TRD by Hood.7.4.2017", a "1-music ON / 2-music OFF" choice, every `LOAD "..." CODE` followed by a `USR` into the loader's sending code; it loads `neart017` for effect 11 (the disk's slip fixed) |
| `byte_diff.py` of the TAP's `neart001` / `neart021` against the SCL's, `z80dasm` | the game pages bank 6 (`$16`) instead of bank 1 (`$11`) for the driver at `$A56B` / `$A58E`; `$C2F9` / `$C308` call `$04C2` instead of NE's `$04D0`; the driver waits for the GS to take each command and selects the effect (`#2E`) before setting its note |

## 2. Stage 1: live runs

Every instance: `python3 tools/gs_session.py launch --work work/stage1/xN --port-base 12340 --model PENTAGON --card
gs|neogs [--card-ram 512k]` (muted, RAM zeroed at power-on), then `steps` and `stop`. One instance at a time, all
stopped. The 1.7 GB `zxbus.1` stream of `x4` was digested into `tap128-host-gs-writes.txt` and deleted.

| Run | Commands (steps) | Proved |
| --- | --- | --- |
| `x1` | SCL, NeoGS: `run:150 insert:SCL script:inputs/scl-boot.txt run:...`, `audiogs:3` | the game reaches the menu (frame ~3000), the card stays silent (capture rms 0) |
| `x2`, `x3` | SCL, GS 512 KB: as `x1`, with `hist:zxbus.1:capture:gs-events.jsonl` (`x3`) | the host writes (`scl-host-gs-writes-a.txt`, `-b.txt`): `#F4 #30 #D1` in frame 555 with no wait. `#F4` restarts the card cold (`COMF4`: `JP 0`, RAM test frames 556-678), so `#30` / `#D1` are lost and the module streams into nothing. The `#3E` of effects 3, 5, 7, 8, 14 were replaced by the `#D1` written right after them (no handle reply). The card ends with `CNTMOD` 0, `CNTFX` 9 (CPU view `$4080`) |
| `x4` | TAP, GS 512 KB, from the 128 menu's Tape Loader: `key:enter:6 insert:hood.tap tape:play run:1500`, `key:1:6 run:3000` | the tape's handshaking loader leaves `CNTMOD` 1, `CNTFX` 14, `MODVOL` `$25`, `FXVOL` `$40`; the module plays (`work/audio/tap-menu-module-30s.wav`). Images `work/images/tap-via128basic-menu-*` |
| `x4` | `gsdata:00 gscmd:32`, then per effect `gsdata:NN gscmd:39 audiogs:S:work/audio/tap-fxNN` (POST `/control/audio/gs`) | every effect rendered from the card (`tap-fx01`..`tap-fx14`) |
| `x4` | `memory_access write gs.ram` of effect 1 XOR `$80`, render; effect 14 back to the files' bytes, render | the sign: the firmware's internal format is unsigned (`COM30` adds `#80` to MOD samples, `PLAY.a80` `SMPMD1`; `#3E` data 0 sets C = `#80` in `LOAD`), the effect files are unsigned (mean neighbour step 1.2-15 unsigned vs 3.9-138 signed). Disk-style flipped effect 1: AC rms 3434 vs 825, step ratio 0.19 vs 0.096; tape's flipped effect 14: 0.321 vs 0.102 unflipped |
| `x4` | `tools/play_gs.py` (NE's `bot.py` with keys) | the first sound in play hangs the machine: PC `$FFFA`, `iff1` 0, `BC` `$7FFD`. Bank 6 is zeros (`tap-via128basic-menu-bank6.bin`): the driver never got there |
| `x5` | TAP from the 128 menu's 48 BASIC, `LOAD ""` | bank 6 still zeros (the menu locks paging) |
| `x6` | TAP from 128 BASIC `PRINT USR 0`, then `LOAD ""`, music ON, `hist:zxbus.1.ports:capture`, `tools/play_gs.py --frames 9000` | the driver at bank 6 `$C000`; a bot game of 9000 frames: the construction menu, 4 robots built, orders given; 102 effects sent (`tap-host-gs-commands.txt`: effect 10 x57, 11 x26, 9 x8, 5 / 12 / 1 x4). Images `tapusr0-menu-*`, `tapusr0-play-*`; screens `tap-01`..`tap-10` |
| `x6` | `poke:FD53:01`, `:FC`, `:FA`, `:C8`, each with `audiogs` (`tap-play-soundfx-*.wav`), host ports in `x6/fx-ports.jsonl` | `SoundFx` 1 -> effect 6 (shot), `$FC` -> 13 (miss), `$FA` -> 13 two frames later (a hit counts up to `$FD`), `$C8` -> 3 (kill); every play with `#2E` n, data `$2F` + `#40`, data n + `#39` |
| `x7` | TRD: `insert:ne-gs.trd script:inputs/trd-boot.txt`, keys 3 / 2 from the saved boot menu | the HRUM boot menu (`trd-01`), `Neart482`'s AY intro (`trd-02`, `trd-neart482-intro-ay-15s.wav`), `Neart481`'s loading screen (`trd-03`), after which the main CPU loops at `$386E` with no more FDC commands (beta128 history): not followed further |
| `x8` | as `x6` on NeoGS | the tape works on NeoGS too: `CNTMOD` 1, `CNTFX` 14, music (`tap-neogs-menu-10s.wav`) |

### 2.1 The card's memory

`python3` byte compares of `work/images/tapusr0-menu-gsram512k.bin` (region `gs.ram`, offset = page x `$8000`) with
the files:

- the module is at `$8000-$29B55`;
- effects 1-13 are back to back from `$29B56`, equal to the files;
- effect 14 is at `$55B27`, equal to the files XOR `$80` from their 4th byte (its first 3 bytes never landed);
- free from `$61B9E`.

Map in [02.3](docs/02-architecture.md#23-the-gs-cards-memory).

### 2.2 Signatures over the images

`kit/sig_scan.py` over the live images and the changed tape blocks (`sig-live-images.txt`):

- The play image and the tape game block give NE's and ANE's entries as on the SCL's `neart001` (`sig-neart001.txt`).
- Bank 6 (the driver), the tape loader and the card's CPU view (GS ROM 1.05a) match nothing: the base has no GS
  firmware or GS driver entries.

### 2.3 Audio (`work/audio/`, capture only, never played)

| File | What |
| --- | --- |
| `tap-menu-module-30s.wav` | the module at the menu (tape load, GS 512 KB) |
| `tap-fx01.wav` .. `tap-fx14.wav` | each effect as the tape stores it, played with `#39` from the host |
| `tap-fx01-as-signed-like-disk.wav` | effect 1 flipped as the disk loader stores it |
| `tap-fx14-as-unsigned.wav` | effect 14 unflipped, as it was meant |
| `tap-play-soundfx-{01-shot,FC-miss,FA-hit,C8-kill}.wav` | the play sounds from `SoundFx` |
| `tap-play-20s.wav` | 20 s of play (module + effects) |
| `tap-neogs-menu-10s.wav` | the menu on NeoGS |
| `trd-neart482-intro-ay-15s.wav` | the TRD's intro (AY, master mix) |

## 3. Stage 2: the source

### 3.1 The split

The lead wrote the game image; three forks, each with its own files and ports, wrote the rest:

| Agent | Scope | Notes |
| --- | --- | --- |
| lead | `src/game/`, `src/res/game/`, `tools/game_*.py`, `tools/build_game.sh`, `tools/res_formats.py`, the integration, README, WALKTHROUGH, docs 08 and README | this file |
| ld | `src/disk/`, `src/tape/`, `src/media/`, `src/res/{music,sfx,screen,text,media}/`, `tools/build_loaders.sh`, `build.sh`, `mk{scl,trd,tap}.py`, `res_media.py`, `basic_tok.py`, `docs/texts/{disk,tape,media}-*` | `work/stage2/NOTES-ld.md` |
| trd | `src/trd/`, `src/res/trd/`, `tools/build_trd_extras.sh`, `hrum.py` (ANE's, copied), `trd_lz.py`, `trd_mkasm.py`, `trd_text.py`, `docs/texts/trd-*` | `work/stage2/NOTES-trd.md` |
| shots | `tools/fig_capture.py`, `fig_screens.py`, `fig_compare.py`, `docs/img/`, docs 01, 05, 06 | `work/stage2/NOTES-shots.md` |

### 3.2 The game image (`neart001`)

The rule for a derived case: the game gets its own full reverse, not Nether Earth's source with patches. Its
annotations started from NE's text and every entry the conversion touched was written again.

| Step | Command | What it proved / made |
| --- | --- | --- |
| a recording of this game | `tools/gs_session.py launch --work work/stage2/r1 --port-base 12340 --model PENTAGON --card gs --card-ram 512k`, then the SCL booted to the menu (`menu.szx`), `l1:work/stage2/r1/l1.json` around `tools/play_gs.py --frames 12000` (log `work/stage2/r1/play.log`), `stop` | `r1`: 12073 frames from the main menu (recording frames 3550-15623), 5 robots built, orders 7 and 3 given; 175 routines ran, 483 checks, 0 divergences. It ran no combat, no capture end, no blast, no save |
| the image from orig/ alone | `python3 tools/game_image.py --out work/mkgame` (`--medium tap` for Hood's) | `neart001` (39536 bytes) at `$6590` in a 64 K image; the TAP's copy differs in 4 bytes (`$A56B`, `$A58E`, `$C2F9`, `$C308`) |
| the seed | `python3 work/stage2/ann/seed_ann.py` | NE's `game.ann` without the entries below `$6590`, the four entries the conversion rewrote (`$A56A`, `$BAEE`, `$CCAC`, `$D5C4`) and two entries that existed only because NE's recordings started there (`$C4E4`, `$D0C7`, merged into their routines); NE's evidence re-attributed ("Nether Earth's deep recording", `nether-earth/docs/...`) |
| the new entries | `work/stage2/ann/gs-additions.ann` appended | the module `gssound` (`GsMenuSound`, `GsSound`, `SpriteSpare`), `NuclearRumble`, `Beep` + `BeepFill`, `SoundEffect` + its fill and leftover, the module `workspace` (`$FCE9-$FFFF` is in the file here: `N1Leftover`, `Variables`, `ImJump`, `ImTable`, `Buildings`, `StackArea`), the `@isub`s that write `PageRom48`, `DriverBank`, `SaveBytesEntry`, `GsDriver` |
| one source, two targets | `case.json` header: `IFDEF HOOD_TAPE` gives `DriverBank` 6 / 1 and `SaveBytesEntry` `$04C2` / `$04D0` | the 4 bytes of the tape's `neart001` come from the same source with `-DHOOD_TAPE` |
| the wrapper | `python3 tools/game_mkgame.py` | `kit/mkgame.py` plus `# @bank` (the driver at `$C000` in another page: not walked, bank 0's `ShapeFactory` data there stays data), `# @var` (the work-space variables are inside the file: labels, `Name+k` operands), `# @alias` (`Handler` = `ImJump+1`); only `case.json` `read_builds` (`stage2/r1`) |
| the text review | `work/stage2/ann/gs_texts.py` and hand edits | every Nether Earth statement checked against this game: the entry from the loader's `JP $A600`; the silent menu loop (8 `OUT ($FE),A` -> `NOP NOP`); the GS ids of every `Beep` caller (`$FA` silent, the chirp's 11 middle ids silent); `SoundEffect` once per event; `NuclearFlash` with GS id 9 and a pause; the two `SaveBytesEntry` targets; the six-pixel mark on every dotted block (the `DI` of `GsMenuSound` at `$A569`); evidence of NE's recordings named as NE's |
| the source | `python3 tools/game_mkgame.py --install` | 577 entries in 24 modules, 4941 instructions (3590 ran in `r1`), 69 operands as `Label+offset`, no `l_` / `sub_` / `data_` label left; "assembled: identical to the original image"; 121 resources into `src/res/game` (94 sources: PNG and text) |
| the build | `tools/build_game.sh` | `neart001-scl.bin` identical to the SCL's, `neart001-tap.bin` (`-DHOOD_TAPE`) identical to the tape's; they differ at `$A56B`, `$A58E`, `$C2F9`, `$C308` |
| the resources | `python3 tools/res_formats.py check` | every source round-trips; the overlap byte `$A569` (`$F3`) is checked by the build. `r1` writes none of the 121 files |

### 3.3 The loaders, the drivers, the BASICs (fork ld)

| Piece | Built | Against | Result |
| --- | --- | --- | --- |
| `src/disk/basic.asm` | `build/disk/basic.bin` (71 = 67 + the autostart mark `$80 $AA 0A 00`) | the SCL's `neart GS` | identical |
| `src/disk/loader.asm` | `build/disk/loader.bin` (865) | `neart022` | identical |
| `src/disk/driver.asm` | `build/disk/driver.bin` (248) | `neart021` | identical |
| `src/tape/basic.asm` | `build/tape/basic.bin` (961) | TAP block 1 | identical |
| `src/tape/loader.asm` | `build/tape/loader.bin` (865) | TAP block 3 (`neart0222`) | identical |
| `src/tape/driver.asm` | `build/tape/driver.bin` (271) | TAP block 47 | identical |
| `src/res/{music,sfx,screen,text}` | `build/res/**` (`python3 tools/res_media.py check`) | the SCL's files, TRD sector 9 | identical |

What the reading found (comments in the sources, [9](docs/09-sound.md)):

- The disk loader's bugs: no waits, so `#F4` (the card's cold restart) swallows `#30` and `#D1` and the module is
  lost; five `#3E` are replaced by the `#D1` after them; effect 11 is the first 401 bytes of `neart019`
  (`neart017` is never read); every effect is stored flipped (signed).
- Both drivers pick the effect of ids 2 and 4 by R in three windows, but R's bit 7 never changes (no `LD R,A` in
  the game, the loaders, the drivers or the ROMs; TR-DOS's three put back an R it read itself): effects 2 and 8
  never play ([9.4](docs/09-sound.md#94-the-driver-neart021-bank-1-c000)).
- Hood's `POKE 23739,111` points channel S's output at `$096F` and hides the "Bytes:" messages.

### 3.4 The TRD extras (fork trd)

`sh tools/build_trd_extras.sh`: `boot` (13 sectors from 1:0), `Neart481` (171 sectors from 103:10) and `Neart482`
(112 sectors from 114:5) identical, every sector with its tail.

- `boot`: BASIC lines 1-3, a REM code `Boot` (`$5D40`) and a HRUM 3.5 block (ANE's macro and depacker,
  `tools/hrum.py` copied from ANE). The packer model gave the original stream but for one tie (output position 2348,
  a 72-byte match at -264, the model's at -132); a rule that fixed it here broke ANE's 13 streams, so the copy got
  `--prefer POS:OFF`, used once. The menu is "Work Loader v1.2, Prepared by TRON 1999" (`$61A8`), annotated in
  `src/trd/boot/menu.ann` and `print64.ann` (a 64-column printer copied to `$8156`); its `Run` writes the chosen name
  into line 3's `RUN "        "` and returns to BASIC.
- `Neart482`: a loader at `$5D49`, then one LZ packer twice (no name, no signature): `tools/trd_lz.py` packs both
  streams back exactly once its policy was found from the mismatches (equal-length run loses to a match, the
  farthest of equal matches wins, no overlap, literal runs cut at 63). The intro `IntroStart` `$5FD9`, the scroller
  at `$78DC`, then the inner game at `$9C40` (NE's `Start` with one byte changed, ANE's view tail and robot menu).
- `Neart481`: the BASIC's REM loader `$5D40` reads six blocks into banks 0, 6, 3, 4, 1 and 0, then the title tune
  (bank 3 `$E1C8`), a sample player (bank 6 `$FDEC`), `FadeAttributes` `$5E2E` and the game at `$A600`. Its five
  blocks are packed with a self-extracting Hrust 1 (depacker at `$5B00`) and stay bytes.

### 3.5 The media

`src/media/scl.txt`, `trd.txt`, `tap.txt` give every file, sector tail and leftover; `tools/mkscl.py`,
`mktrd.py`, `mktap.py` write the images. The TRD's leftovers are kept as documented bytes (`src/res/media/`): the
catalogue entry 28 is both the end mark and an old entry whose sectors 1946-2116 hold a whole copy of `Neart481`;
free sectors 1941-1942 are `Neart482`'s sectors 110-111 of an older write; the tails of `neart021` and `neart022` are
one catalogue sector of the author's work disk; sector 9 has 10 spaces at `$EA-$F3`.

### 3.6 The texts

Owner request: every text on the media as UTF-8 Markdown with English, and as a build resource that converts back
to the exact bytes. Nine readable copies in `docs/texts/` (index in [8.2](docs/08-hud-and-text.md#82-the-texts-on-the-media)),
the resources in `src/res/text/`: the BASICs through `tools/basic_tok.py`, sector 9 and the label through
`res_media.py` / `mktrd.py`, the TRD extras' five texts through `tools/trd_text.py` (an encoding line, `|` line ends,
`\xNN` for odd bytes).

### 3.7 The screenshots against NE (fork shots)

Owner request: per medium the boot and loading screens, the GS-512 screen, the tape's music question, the menu and
play, and the hang, side by side with NE at the same moment.

| Run (instance) | Steps | Proved |
| --- | --- | --- |
| A: Pentagon 128 + GS 512 KB, `poweron.szx` | `run:100` | the 128 menu; the snapshot every route starts from (gs_session has no reset) |
| A: SCL | `scl-boot.txt` (RUN "neart GS"), shots at +300 / +1200 / +3200, key 0, +300 | the loading screen, the GS-512 label painted by the loader's `$5861-$5864` bar, the menu, the start of play |
| A: TRD | `trd-boot.txt` (RUN), then keys 3 / 2 / 1 from `trd-bootmenu.szx` | the HRUM boot menu; `Neart482` intro; `Neart481` stops after its loading screen ("CRACKED BY TRON'1997"), regs PC `$0049`, `iff1` 0, IM 1 at +2206; entry 1 = the SCL's game |
| A: TAP, 128 menu Tape Loader | ENTER, insert, play, key 1 (music ON), `play_gs.py --frames 800` | the Tape Loader screen, the music question, the menu; the bot stops at the warbase pad ("the pad is blocked" in play.log), PC `$FFFA` halted, `iff1` 0, `BC` `$7FFD`; the frame 500 frames later is identical |
| A: TAP, 128 BASIC `PRINT USR 0`, `LOAD ""` | typed by `key:` steps, music ON, `run:13000`, `play_gs.py --frames 1100` | the route that plays: loading screen at ROM pace with ROM border stripes, menu, construction / robot / orders / target screens |
| NE: 48K, no card, `NETHER.TAP` | `LOAD ""`, `run:14500`, key 0 +300; `nm1-6` 20 frames apart; `play_gs.py --frames 900` from `ne-menu.szx` | NE loads into a black screen with random border colours (N1), menu after ~14500 frames; NE's title cycles colours (nm2 black phase looked like a missing title at first); NE's construction menu at the same bot step |

Screen-area (256 x 192) comparisons, `fig_compare.py`: GS menu `u-g` = NE `nm3`, GS `scl-e-play` = NE `ne-play`,
GS `uplay/tap-04` = NE `play/tap-04`: 0 differing pixels each. Robot menu / orders / target differ only in the clock
and robot positions (the bot reaches them on different frames).

### 3.8 The whole build

```sh
tools/build.sh
# build: identical to build/orig/NE_GS_TZ.SCL
# build: identical to orig/Nether Earth (1987)(Argus Press Software Ltd)(EN)(GS)[h 2002 Tron Z].trd
# build: identical to orig/Nether Earth (1987)(Argus Press Software Ltd)(EN)(GS)[h 2017 Hood, Tron Z].tap
python3 ../../kit/check_docs.py --case .
```

## 4. Tool gaps

### 4.1 Stage 1 (unreal-ng and the kit)

1. **The GS-side `COMRG` read is logged with value 0.** The `zxbus.1` history records the card's `IN` of its command
   register (port 1) with `value` 0, not the command byte, so the card's view of each command cannot be read from
   the history. Only the host side (`zxbus.1.ports`, `side` host) shows it (`x3` `gs-events*.jsonl`).
2. **`mm_session.KEY_NAMES` maps `SS` to `symbol_shift`**, a name `DebugKeyboardManager` does not know (it has
   `symbol`, `sym`, `symshift`, `sym_shift`, `ss`). The press fails quietly: in `x4` the fire key held as
   `symbol_shift` left `Input` bit 4 clear, and `symbol` set it. The boot scripts' `ss P` typed no quote.
3. **NeoGS state is not in the SZX**: `snapshot/save` warns it on the NeoGS runs, so a NeoGS session cannot be resumed
   from a snapshot. The classic GS runs saved and reloaded.
4. **The signature base has no MOD detector** (only PT2 / PT3): the ProTracker module in `neart002-006` was found by
   a header parse, not by `sig_scan`. It has no GS ROM / GS driver entries either (4).
5. **No GS command / variable view by name**: the firmware variables (`CNTMOD`, `CNTFX`, ...) were read as raw bytes
   at the GS CPU's `$4080`. `/state/audio/gs` gives channels and the latches, not the firmware's tables.
6. **History volume**: `zxbus.1` in capture mode wrote 1.7 GB for a 2600-frame tape load (15 M lines, mostly the card's
   idle polls and interrupts). There is no filter for the host's port writes alone besides `zxbus.1.ports`.

### 4.2 Stage 2

1. **`kit/mkgame.py` knows one RAM page at `$C000`.** The driver is in another page; the case's wrapper adds
   `# @bank` (not walked, the disassembler's entry mark dropped) as ANE's did. A kit-level directive would serve both.
2. **In-image variables.** `@equ` is for names outside the image; this file holds its work space, so the wrapper adds
   `# @var` (labels plus `Name+k` operands) and `# @alias` (`Handler` = `ImJump+1`).
3. **One source, two targets.** mkgame assembles one image; the second target (`-DHOOD_TAPE`) is built and compared
   by `tools/build_game.sh`.
4. **A resource that overlaps code** (`$A569`): `@res` cannot share a byte with an instruction, so the sprite's file
   stops one byte short and `res_formats.OVERLAP` checks the byte.
5. **mkgame takes one image** and installs into `src/game`: `tools/trd_mkasm.py` wraps it for the boot menu.
6. **L1 reads polluted by a depacker** and **L1 instructions by address only**: a later program's code at the same
   addresses leaks in; `trd_mkasm.py` takes a recording's instructions per whole basic block. A first / last frame per
   block in L1 would let a tool cut a recording to one program.
7. **No signature** for `Neart482`'s LZ or the self-extracting Hrust 1, and **no packer** for the latter.
8. **`kit/tap.py`** is CLI only; `tools/mktap.py` imports its functions.
9. **`gs_session.py`**: no `reset` step; `--card none` prints `Unknown action 'slots_unplug'`; zsh passes a step
   string as one argument; the 128 menu needs `key:down`, the quote is `symbol+p`.
10. **Reproducibility of tape frames**: the tape is started by a separate call between steps, so 5 of 52 loading
    frames differ between runs.

## 5. What stays unexplained

- `Neart481` stops in the emulator (PC `$0049` / `$0048`, interrupts off, after its title tune; stage 1 saw a loop at
  `$386E`): not followed further. Its packed blocks stay bytes.
- `Neart482`'s intro code (`$67F8`, `$8235`) and its inner game (40536 bytes) stay resources; the inner game is
  not reversed.
- The GS playback rate of the effects (the WAV headers give a nominal 11025 Hz).
- The code in `neart001`'s TRD tail and in free sector 1943, the bytes of sector 1945; the first letters of the
  leftover catalogue names ("?.EARTH", "?TS6.0").
- The game: no recording of this case ran combat, the blast, a game's end or the tape save; those parts rest on the
  code and on NE's experiments (the same bytes), which the annotations name as NE's.
