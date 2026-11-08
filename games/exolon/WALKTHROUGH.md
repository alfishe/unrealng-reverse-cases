# Exolon: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

The release: ZXDB's `Exolon.tzx.zip` (the perfect TZX of the Hewson cassette), chosen over the collection's 18
TR-DOS copies (all cracks) and over `Exolon.tap.zip`, which proved a modified copy (docs 3.1).

```bash
unzip -o orig/Exolon.tzx.zip -d work/media/tzx
python3 tools/tape_files.py work/media                     # the BASIC, the loader, picy, the code
python3 tools/tzxblocks.py list work/media/tzx/Exolon.tzx    # 8 standard blocks, 265.4 s; headers 5 and 7 of type 42
python3 tools/basic_list.py work/media/exolon.bas            # CLEAR 25999, LOAD "" CODE, USR 64512
python3 tools/xorchain.py decrypt work/media/loader.bin work/media/loader1.bin
python3 tools/picy.py unpack work/media/block6.bin work/media/loading.scr
python3 tools/image.py work/mkgame/original.bin              # $6D60-$FFFF
python3 ../../kit/sig_scan.py work/media/game.bin --base 6D60 --all --out work/stage1/sig-game.json
```

- The tape is Zynaps' layout: BASIC, the 768-byte Countdown II loader at `$FC00`, a 4096-byte `picy` loading
  screen, the game. `tzxblocks.py`, `basic_list.py`, `picy.py unpack` came from the Zynaps case unchanged and read
  it at once.
- The loader's XOR chain is 656 bytes (Zynaps 652). Zynaps' `xorchain.py` had the range fixed; it now reads it
  from the plain head (`LD BC` / `LD HL`) and decrypts and re-encrypts Exolon's loader byte for byte. The stages and the move
  were read off the plain loader by hand: the game lands at `$6D60-$FFFF` and starts at `$6D60`.
- The signature scan finds no known module: three one-anchor candidates (Zynaps' control data at `$ACDB`, Nether
  Earth GS's workspace at `$FCE9`), each with over 100 bytes different: leads only.

## 1. One recording from power-on

```bash
python3 $RS capture --work work/c1 --media work/media/tzx/Exolon.tzx --model 48K --record-load --frames 16000 \
    --port-base 18900 --binary $BIN
python3 $RS stages --work work/c1
python3 tools/check_load.py --work work/c1
python3 tools/picy.py check                  # 2850 literals, 844 masks, 108 flags: repacked exactly
```

- `c1`: 12 700 load frames, then 16 000 frames of seeded random play. The random play started the game from the
  menu several times (`work/c1/screens.png`: the menu, the first screen with the lives running down). L1: 334
  routines, 1576 blocks over 28 760 frames.
- `stages` gives the six arrivals of the static decode (docs 3.5): the loader at frame 250 (the fast load took the
  ROM blocks), the decrypted loader at 251, picy at 1808, MoveStub at 12 364, the game at 12 376 T 62 848.
- `check_load.py`: the decrypted loader, picy, the code file and the moved image are equal to the static decode
  byte for byte; the screen differs in 24 bytes, the countdown's digits.
- Two things in the image read before any run, then checked in `c1`'s L1:
  - `$BF6D-$BF7D` writes an AY register through `$FFFD` / `$BFFD`; it ran in `c1` (17 of 17 bytes executed) on a
    48K, where the ports go nowhere: the game drives the AY whatever the machine;
  - `$C7B5-$C7F0` reads a keyboard matrix through ports `$F4xx` / `$F6xx`, the Amstrad CPC's PPI and PSG: 0 of 60
    bytes executed in `c1`. A lead for doc 2 (code of the CPC version left in the image?), to be settled by L1 over
    every recording and by the callers.
- `c128`: the same capture on the 128K model (port base 19500). The stages are the same (the game entered at frame
  12 157 T 34 660; the 128K ROM's own `$5B00` code shows as one more arrival at frame 53). No write to `$7FFD`
  anywhere in the image: the game pages nothing.
- The machine test, read in the image, then checked against the ROMs: the entry at `$6D60` reads the ROM byte
  `$386E`, subtracts `$FF` and keeps the result at `$6E16`. The 48K ROM has `$FF` there (flag 0), the 128K's 48
  BASIC ROM `$DD` (`48.rom`, `128.rom` of the emulator). The flag picks the sound: the beeper routines `$7C26` and
  `$7C40` return at once when it is set, and `$6DC5`, `$6F23`, `$9597` branch on it. The "48K / 128K" of the tape
  is this one image with a beeper and an AY path.

## 2. Static pass over the medium

The tape's blocks were decoded without the emulator first (docs 3.1-3.4): `tools/tzxblocks.py list`,
`tools/basic_list.py`, `tools/xorchain.py decrypt` (the loader in the clear), `tools/picy.py unpack` and `check`
(the screen, repacked exactly), `tools/image.py` (the game as the move leaves it). Each matched `c1`'s memory at
the stage it belongs to (section 1, `tools/check_load.py`).

## 3. The stages and the packers

Zynaps' Countdown II loader and picy packer, both reused: the loader with a longer XOR chain (656 bytes), the
counter moved to the bottom right, a type-42 check in `LoadFile`; the picy unpacker byte for byte the same.
Details in docs 3.3 and 3.4.

## 4. The medium from source

Zynaps' tape sources copied and changed to Exolon's bytes (docs 3.6): the BASIC (`CLEAR 25999`), the loader (the
assembled plain loader compared with `xorchain.py decrypt`'s output until equal: the four differences listed in
3.6, plus Zynaps' padding reads of `($8000)` kept as they are), the picy block (only the zero fill at its end
changed), the block list `src/tape/exolon-tzx.txt` (types 42 for blocks 5 and 7, a form `tools/tzx.py` gained).
`rm -rf build && tools/build.sh` prints "build: Exolon.tzx identical to orig/Exolon.tzx.zip's Exolon.tzx", with the
game from the mechanical cut (`kit/mkgame.py --install`, an empty `game.ann`): 10 337 code bytes from the
recordings in `case.json` (`c1` with its reads; `c128`, `x1`, `x2`, `w030`, `m1` and the 97 warp runs for their
instructions only). `h1` is left out: its clone turns `$6D88-$6D94` into NOPs, and the NOP at `$6D92` falls on a
zero byte of the image (`LD BC,$0005`), so the cut would start an instruction there.

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |

## 6. The game

### 6.0 First experiments (2026-11-08)

Recordings from `work/snaps/entry.z80` (`tools/entry_snapshot.py`: `c1`'s memory at the game's entry, frame 12 376
T 62 848, PC `$6D60`), input scripts written by `tools/inputs.py` from (keys, frames) pairs. Every run below on a
clone with POKEs is exploration only, named as such; no claim about the game rests on it alone.

- `x1` (`tests/inputs/x1-right.txt`, no POKE): the menu takes 5 (Kempston) and 1 (start game) when each is held
  30 frames (5-frame taps were missed); the first screen's gun kills the player again and again; GAME OVER, the
  menu, and in the attract cycle a high-score table (SURTANI, SCRAGGY, SABATTA!, PADDY, LOFTY, JIMBO, LEO, GLEN,
  MORANGE, all 001000).
- The ZXDB POKE file's addresses hold what it says in this release: `$9D1D`, `$836E`, `$9250` are the `DEC A` of
  the lives (`$8E7A`), the ammunition (`$8E5A`) and the grenades (`$8E66`).
- The grenade, read in the code: the main loop's pass calls `$8338`, which counts the passes the fire button is
  held in `$83DC` (a shot on the first); `$9208` throws a grenade when the count reaches 15, none is in flight
  (`$925A` = 0), the player's X (`$82F5`) is below `$76` and grenades are left. In `x2` the count rises one every
  2 frames while fire is held: a pass takes about 2 frames.
- `x2` (`tests/inputs/x2-imm-right.txt`, on `entry-imm.z80`: the ZXDB POKEs for lives, ammunition, grenades,
  immunity, mines and traps): fire held 40 frames, then right, a jump and a shot, repeated. It passes 5 screens in
  3000 frames (the counter `$8523` 0 to 5 at frames 751, 1481, 1771, 2421, 2951), then stalls before a dome on a
  pedestal.
- The screen number: `$8523`, set to 0 only at the entry (`$6D75`), raised by one at `$825C` as the player walks
  off the right edge, printed as ZONES (`$8E7B`, row 23 column 28), read by the screen builder at `$84D7` (the
  table at `$C7F4`). At `$A867` screen 124 (`$7C`) ends the round: `$8523` goes to `$FF`, a life is added up to 9,
  ammunition and grenades are refilled, and the next screen is 0 again.
- `tools/warp_snapshot.py N`: `entry-imm.z80` with the entry's store to `$8523` turned into NOPs and `$8523` = N.
  `w030` started on screen 30 and walked to 32. `tools/warp_runs.sh 0 5 120` records 25 such runs (one per fifth
  screen) for the code coverage of the screens no plain run reached. A second batch (`tools/warp_runs.sh list
  ...`) filled in the start screens between; together 97 warp runs in `work/w/NNN`, every screen 0-124 reached.
  Some runs never left their start screen (5, 7, 22, 25, 26, 29, 35, 39, 40, 41, 43, 48, 50, 55, 65, 67, 68, 69,
  75, 79, 84, 94, 98, 104, 110, 114, 115, 116, 118, 119, 123): each of those screens is still built and played,
  which is what the coverage needs.
- The warp run on screen 124 walks off its right edge and takes the round end of `$A867`: the CONGRATULATIONS
  text at `$AA3F`, then `$A8DB`, the bonus screen ("EXOLON BONUS SCREEN! PRESS FIRE TO STOP POINTER", `$A961`): a
  pointer `*` steps round eight places (`$A960` counts), fire stops it, and the place it stops on (when odd) adds
  that many bonuses through `$AD53`.
- `m1` (`tests/inputs/m1-menus.txt`, no POKE): the menu options 2 (define keys), 3, 4, 5 and 1, nine deaths,
  GAME OVER, the menu again.
- `h1` (`tests/inputs/h1-hall-of-fame.txt`, a clone: `work/snaps/entry-score.z80`, the score `$AD8A` = 009000 and
  the entry's reset of it at `$6D88-$6D94` turned into NOPs): after the ninth death `$A073` compares the score
  with the table at `$71F1` (16 bytes an entry, the score at +10), moves the lower entries down, and asks for the
  name ("CONGRATULATIONS! PLEASE ENTER YOUR NAME INTO THE EXOLON HALL OF FAME"); EXOLON and ENTER put it at the
  top. On ENTER `$A13A` sets `$71F0` to 1 and jumps to the entry `$6D60`, which then goes straight to `$7145`:
  the flag cleared, the Hall of Fame shown (the same display the menu's timeout reaches at `$7149`).
- `python3 tools/coverage.py <work folders>` counts the game bytes the recordings executed (the L1 blocks, each
  to its last byte). `c1`, `c128`, `x1`, `x2`, `w030` and the 97 warp runs: 10 960 of the
  37 536 bytes (10 963 before a fix to the tool: it counted past each block's last byte). `m1` and `h1` add 148 (`$7145-$7148`, `$A095-$A101`, `$A122-$A144`: the table insert and the
  name entry). Not executed in any run: the CAPS delete of the name entry (`$A102-$A121`), the Amstrad keyboard
  code at `$C7B5`, and the data.

### 6.1 The annotation, five agents (2026-11-08)

Recipe 11: the image cut into five ranges (`$6D60-$802C`, `$802D-$910A`, `$910B-$9E36`, `$9E37-$ADE0`,
`$ADE1-$FFFF`), one agent each with the brief `work/briefs/ann-fragments.md`, own port bases (24000, 24600, 25200,
25800, 26400), each fragment checked alone with `kit/mkgame.py` ("assembled: identical") before the merge.

- `case.json` read builds: the first two agents found that no `c` entry on code that never ran was accepted ("the
  recordings say data"). `c1`'s L1 counts every byte of the image as read: the loader's move reads the code file,
  and `Delay` (`$B0B7`) is an `LDIR` from `$0000` to `$0000` of BC bytes, which reads every byte up to BC. The
  read builds are now `m1` and `x1` (no POKE, both from the game's entry); `c1` (`game`) counts for its
  instructions only. With that the never-run code is `c` entries: `$7014`, `$7046`, `$7BDB`, `$7FF1`, the CAPS
  delete in `$A095`, `$AC2B` (the force field destroyed), `$AD2A` (the pause), `$C7B5` (the Amstrad keyboard
  scan), `$FF78` (a serial downloader), and others, each description saying why it never ran.
- The agents' own runs (exploration on clones, `work/ann/<id>/`): exA's `exa1` (define keys with ZORBA: the cheat
  toggles the lives' `DEC A` at `$9D1D` to `NOP`; ten deaths, no life lost), exC's `t1` / `t2` (screen 14 with
  only the lives and immunity POKEs, so the traps run: 1047 passes of the trap body), exD's `d1` (the pause, and
  the CAPS delete: the table read back `EOLONABD  009000`, as the code predicts).
- The merge, `work/lead/merge.py`: the fragments in address order, six names two agents gave to different
  routines renamed (`ClearMenuStars`, `WaitKeyOrFire`, `WaitKeyOrFireKey`, `BeeperTuneNote`, `AyTuneNote`,
  `HudDigit`), 15 jump targets named by the lead (`work/lead/names.ann`), the mechanical names in comments
  replaced by the entries' names, seven `@equ` (the cell maps `$5B00`, `$5E00`, `$6100`, the tables `$6400`,
  `$6500`, `$6600`, `$6700`), 15 `@isub`, and 34 modules cut by address. Result: 484 entries, 11 278 code bytes,
  "assembled: identical", `tools/build.sh` identical, docs 11 and 12 regenerated (287 routines, 197 data
  entries).
- `tools/coverage.py` fixed (exC): the L1 block's `end` is its last byte; the tool had added an instruction length.

## 7. Review
