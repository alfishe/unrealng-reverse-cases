# 9. Sound

What this covers: the General Sound card and what the game asks of it, the driver in bank 1, the media (13
Protracker modules and 22 sampled effects), where the game makes each sound, what happens on a 128 KB card, and the
beeper code left behind. This is the stage 1 draft. The runs it rests on are in `work/stage1/NOTES.md`:

- `x1`: Pentagon 128 with a GS 512 KB, in music mode and in effects-only mode;
- `x2`: Pentagon 128 with a GS 128 KB, in both modes.

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - the tunes as charts -->
<!-- - the card's memory after each upload (module, FX, the wrap on 128 KB) -->
<!-- - a routine animation of the driver -->

## 9.1 The machine and the card

The game needs a 128K machine with TR-DOS and a General Sound card. It uses banks 1, 3, 4, 6 and 7, all on `$7FFD`.
The card runs only its ROM firmware: no code is uploaded to it. The game uses these firmware commands
(`COM_H.a80` in the firmware sources):

| Command | Firmware name | Use here |
| --- | --- | --- |
| `#23` | pages | the number of 32 K RAM pages; it decides the load-once path (9.5) |
| `#F3` | warm reset | the card is emptied before every load |
| `#30` / `#D1` / `#D2` | load module, stream open / close | a level's module |
| `#38` / `#D1` / `#D2` | load FX | each effect |
| `#2A` / `#2B` | module / FX volume | per level (`$64E5`), and FX `$40` |
| `#31` / `#32` | play / stop module | |
| `#2E` / `#40` / `#80+c` | select FX, FX note, play in channel c | most sounds |
| `#45` / `#39` | FX default volume, play FX | the C1DF sound in music mode |
| `#41` | FX volume | the C095 sound |
| `#3A` | stop FX (mask) | in `$C27D`, which has no caller found |
| `#48` / `#49` | FX loop points | in `$C28F` / `$C2AD`, which have no callers found |

The menu chooses between two modes. Key 1 is "START MUSIC & EFFECTS" and key 2 is "START ONLY EFFECTS". The choice is
the flag `$B486`: 0 means music, 1 means effects only. In both modes the title page plays the title module (level
13). In play, the music mode has a module and 10 effects. The effects-only mode has no module and 21 effects.

## 9.2 The driver (bank 1 `$C000`)

The game calls the stubs at `$FF1C..$FFC3`, `$B2F0`, `$B47F` and `$A6AE`. Each stub loads HL with a bank 1 entry
and goes through `$B466` / `$B482`, which page bank 1 (`$11`), call the entry and page bank 0 back (`$10`). The core
routines are:

- `$C23C` (`$C23B` with the gate skipped) plays FX L at note H in channel C:
  - data L, `#2E`;
  - data H, `#40`;
  - data L, `#80|C`.

  Each command waits at `$C2E7` (`IN $BB`, bit 0), and each data byte at `$C2ED` (bit 7).
- `$C24F` plays the same sound through the FX's own channel choice: `#2E`, `#40`, then data B with `#45`, then data L
  with `#39`.
- `$C22A` is the gate. If (`$7F6A`) = `$C0`, the sound plays at once. Otherwise, the sound is dropped while the
  countdown `$AA29` is not 0; when it plays, the countdown is set to the immediate at `$C237`. That immediate is the
  menu's "EFFECTS TIMER" (2 at start; key 7 steps it, 3 seen). The countdown is stepped by the stub at `$AA28`. So the
  timer is the minimum number of steps between two gated sounds.
- `H` is often given 0..1 or 0..3 random semitones from `LD A,R` (the tables below show this as "+r&1" / "+r&3").
- `$C303` sends `#23`. If the card has 7 pages or more and the mode is effects only, it does the following once:
  - sends `#F3`;
  - turns `$C2FD` (the `#F3`) and `$C303` into `RET`;
  - writes `INC L` at `$C23B` and `$C260`, and `$16` at `$C0BE`.

  From then on, every FX number is one higher, because the start jingle stays in handle 1 (9.5).
- `$C328` sends `#2B` with (`$B45F`). `$C333` sends `#2A` with (`$B460`), then `#31 1`.
- `$C385` is the level change, and does nothing if (`$B461`) = (`$B462`). Otherwise it does the following:
  1. Switches to IM 1.
  2. Saves `$BE00` (`$200` bytes) to `$CF90`.
  3. Swaps the level loader in at `$61A8` (bank 1 `$C44A`, `$419` bytes) and the `$5B00` area with `$D190`.
  4. Sends `#23` and `#F3`.
  5. Branches on (`$B463`): 0 is a new level, 1 is the game start (the jingle), 2 is the title.
  6. Swaps everything back and returns to IM 2.
- `$C34C` replaces Zynaps's wait of N frames between rounds (`$A6AE`):
  - In effects-only mode it is a fixed delay.
  - In music mode, `$C86C` fades the module out (`#2A` from (`$B460`) down to 0, one step per delay) when N = 2 and
    (`$B073`) ≠ 6. Otherwise it is the same delay.

The level loader (runtime `$61A8`) has three entries:

- `$61A8` uploads the jingle from bank 1 `$D3CB` and plays it: FX 1, note `$33`, channel 1.
- `$61BF` uploads the 10 in-game FX. They start at bank 1 `$FAA5` and run on through the pages `$11` → `$13` →
  `$14` → `$16` (the length list is at `$64F6`). In effects-only mode it then uploads the disk set (11 FX, records
  `$63B6..$63C8`) and sends `#2B $40`.
- `$6277` uploads the module of level (`$B461`) record by record. The table at `$64CB` holds each level's first
  record. A record is 6 bytes:
  - the number of sectors;
  - flags: bit 1 means Trush-packed, unpacked by `call $BED4` in page `$17`; bit 7 means the last record; bit 0 means
    delta-coded, and is never set;
  - 2 bytes that the start-up code at `$6332` fills with the track and sector;
  - the negated length.

  Each byte is streamed with the bit-7 wait.

## 9.3 The media

`tools/gs_media.py` cuts all the media from the disk the way the loader uploads them, into `work/media/gs/`
(`media.json` gives the sizes, the SHA-1 and the source of each). It then compares them with the streams cut from
the live port histories (`work/tmp/streams.py` → `work/media/streams/`):

- every one of the 22 effects that both modes upload matches a live stream byte for byte;
- the modules of levels 13 (the title), 1 and 2 match byte for byte;
- the other 10 modules have not been streamed live yet.

**Effects.** They are 8-bit unsigned PCM, played at the note the game gives (`work/audio/fx/*.wav`, rendered by the
card at that note).

| FX | Bytes | From | The game's use (9.4) |
| --- | --- | --- | --- |
| start | 9946 | bank 1 `$D3CB` | the game start jingle, note `$33` |
| 1 | 650 | bank 1 `$FAA5` | `$C208` |
| 2 | 5207 | bank 1 `$FD2F` | `$C21D` |
| 3 | 5006 | bank 3 `$D186` | `$C20D` |
| 4 | 1396 | bank 3 `$E514` | `$C191`, `$C19D` |
| 5 | 6308 | bank 3 `$EA88` | `$C1B2` |
| 6 | 1347 | bank 4 `$C32C` | `$C212` |
| 7 | 9562 | bank 4 `$C86F` | `$C1BD`, `$C153` |
| 8 | 10679 | bank 4 `$EDC9` | `$C1D0`, `$C153` |
| 9 | 3827 | bank 6 `$D780` | `$C1DF` |
| 10 | 6548 | bank 6 `$E673` (its last 7 bytes come from bank 7 `$C000`, zeros) | `$C1DF` |
| 11-12 | 11282, 4216 | blob 321 (raw) | `$C153`; `$C113` |
| 13-16 | 3450, 3554, 2516, 4464 | blob 382 (Trush blk05) | `$C113`; `$C113`; `$C17F`; `$C018` |
| 17-20 | 4589, 1442, 3532, 4147 | blob 429 (raw) | `$C13E`; `$C010`; `$C02B`; `$C018` / `$C02B` |
| 21 | 9144 | blob 483 (Trush blk06) | `$C095` (it is bytes 13318-22461 of sample 8 of level 7's module, sign flipped) |

FX 11-21 are on the card only in effects-only mode. In music mode the entries that use them send FX numbers the card
does not have. Stage 2 is to check what the firmware does with those numbers.

**Modules.** All 13 are Protracker `M.K.` with 31 samples. They are rendered in full by openmpt123 to
`work/audio/mod/levelNN.flac`, and their names are in `work/stage1/texts/module-names.txt`.

| Level | Bytes | Volume (`#2A`) | Length | Title / credits in the sample names |
| --- | --- | --- | --- | --- |
| 1 | 59392 | `$1A` | 2:46 | "from_wendetta_2175!", ripped_by_dangerous, by_wortex_design |
| 2 | 42496 | `$20` | 1:40 | "zynaps2" |
| 3 | 37376 | `$3C` | 1:04 | untitled |
| 4 | 40960 | `$28` | 2:49 | "zynaps4": kbx128 / tesko!, october 1994, for "galaga deluxe" |
| 5 | 56320 | `$40` | 1:44 | untitled |
| 6 | 28672 | `$20` | 0:08 | untitled, sample 1 "John Underwood" |
| 7 | 54016 | `$40` | 1:32 | untitled |
| 8 | 44544 | `$20` | 1:40 | "zynaps5" |
| 9 | 53910 | `$40` | 1:17 | untitled |
| 10 | 26368 | `$20` | 0:38 | "zynaps6": nuke of lemon |
| 11 | 41216 | `$20` | 1:40 | "zynaps3": MagFields by dextrous, 1990 |
| 12 | 48128 | `$26` | 4:36 | "zynaps1": music by pyratronik |
| 13 (title) | 51456 | `$40` | 1:32 | untitled |

Several modules carry "Noiseconverter of / Buggs/Defect used" in samples 30-31, which is Noiseconverter's
signature. The credit "MUSIC & FX MIXED BY: JOHN UNDERWOOD & DANGEROUS" is the menu's.

## 9.4 Where the game makes a sound

All the sites are patched by the installer (3.5). Zynaps's beeper request `$B2F0` takes the sound number in A. A
number lower than the one pending is dropped, and 0 counts as `$80`. The request sets bit 0 of `$81C5` for the
player `$B30C`.

Here "music" is the music mode and "fx" is the effects-only mode. FX numbers are those of the music mode; in
effects-only mode with 7 or more pages they are one higher (9.2). "Seen" counts the hits in two 3000-4000 frame
scripted plays of level 1 (`work/stage1/x1/hook1-counts.txt` for music, `hook2-counts.txt` for effects only), counted
by the memory profiler's executions at each stub. The stage 1 names are what the code shows; the game events are to
be named in stage 2 against the game's own logic.

| Zynaps site | Was | Stub → entry | Sound | Channel music / fx | Seen music / fx |
| --- | --- | --- | --- | --- | --- |
| `$A31D` | beeper sound 4 | `$FF7B` → `$C208` | FX 1, note `$26` | 1 / 2 | 0 / 0 |
| `$A226` | beeper sound 5 | `$FF81` → `$C21D` | FX 2, note `$32`+r&3 | 1 / 1 | 0 / 0 |
| `$A21F` | beeper sound 6 | `$FF75` → `$C20D` | FX 3, note `$32` | 1 / 1 | 0 / 0 |
| `$A1C4` | beeper sound 1 | `$FF60` → `$C191` | FX 4, note `$30`+r&1 | 1 / 1 | 2 / 2 |
| `$9EA5` | beeper sound 3 | `$FF69` → `$C212` | FX 6, note `$3C`+r&1 | 1 / 2 | 0 / 0 |
| `$9C77` | beeper sound 2 | `$FF6F` → `$C1DF` | FX 10, note `$32`, if (`$7FA6`) ≥ 2, else FX 9, note `$34`; +r&1; none if (`$B465`) bit 0 | music, (`$B465`) bit 1 clear: `#45 1` + `#39`; else 1 | 4 / 5 |
| `$ABF1` | beeper sound 0 | removed (`NOP`s) | none | | |
| `$9B51` | `jp $9B5F` | `$FF44` → `$C1D0` | FX 8, note `$2D`, ungated | 1 / 0 | 7 / 9 |
| `$9FBE`, `$A034` | `call $A293`, `call $A2A5` | `$FF3B` → `$C1BD` | FX 7, note `$2C`+r&3 | 1 / 0 | 1 / 2 |
| `$9CA6` | `ld (ix+$12),a` | `$FF56` → `$C19D` | FX 4, note `$2A`+r&1 | 1 / 2 | 0 / 0 |
| `$9CFA`, `$9D1F` | `call $9CB0` | `$FF4D` → `$C1B2` | FX 5, note `$32`+r&1 | 1 / 2 | 0 / 0 |
| `$95E7` | `ld hl,0` | `$FF8F` → `$C17F` | if D bit 7 is clear: FX 15, note `$2D`+r&1 | 3 | 0 / 0 |
| `$A0BA` | `dec (iy+$0D)` | `$FF99` → `$C113` | on levels 7 and 11: FX 12, note `$2C`+r&1; else FX 13 + r&1, note `$31`+r&3 | 0 | 0 / 0 |
| `$A0D5` | `ld ($80E2),a` | `$FFA3` → `$C153` | music: as `$C1D0`; fx: FX 11 (`$28`+r&3, ch 0), FX 8 (`$2D`, ch 1), FX 7 (`$2C`, ch 2), FX 11 (note + 1, ch 3): all four channels | | 0 / 0 |
| `$9823` | `ld hl,0` | `$FFAC` → `$C010` | FX 18, note `$3A` | 3 | 0 / 0 |
| `$9856` | `ld (iy+$1B),1` | `$FFB6` → `$C13E` | FX 17, note `$3C` on level 4, else `$28` | 0 | 0 / 0 |
| `$969D` | `call $989F` | `$FFC3` → `$C02B` | by the object's graphic (DE): `$6850` or E = `$EE` → FX 19, note `$28`; `$6846` → FX 20, note `$24` | 3 | 0 / 0 |
| `$9694`, `$9747` | `call $9529` | `$B2F0` → `$C018`, then `$9529` | by DE and C: `$682C` / `$0A` → FX 16, note `$3C`; `$68F9` / `$12` or `$685B` / `$11` → FX 20, note `$28`; else with (`$B464`) ≠ 0: `$C095` (`$6820` → FX 21, note `$32`, `#41` = (`$B45F`)/4, at most once per 8 calls per object slot, and only when the slot's B changed); else `$C02B` | 3 | 865 calls / 850, no sound |
| `$9954` | `ld l,(iy+0)` | `$B47F` → `$C0D5` | clears the object's slot at `$C103` (the `$C095` counter) | | 2 / 4 |
| `$B075` | `ld de,8` | `$FF87` | (`$B462`) = the next level; no sound | | 0 / 0 |
| `$B03E` | `call $91C6` | `$FF1C` → `$C385` | the round start: loads the level's sound when the level changed | | 6 / 8 |
| `$AF51` | `ld ($80B0),a` | `$FF26` → `$C385`, (`$B463`) = 1 | each "PREPARE FOR COMBAT": the jingle on a game start | | 6 / 9 |
| `$B102` | `call $A6AE` (wait N frames) | `$A6AE` → `$C34C` | the music fades between rounds (music mode) | | 6 / 9 |
| `$B204` → `$AA33` | | | the title: (`$B463`) = 2, loads the title module once | | |

The two plays reached only part of level 1: the hooks with 0 hits were not triggered. The level change itself was
proved by poking (`$B462`) = 2 before a death: the next round start sent `#23`, `#F3`, the jingle, level 2's module
(42496 bytes, identical to `level02.mod`), the 10 FX and `#2A $20` (`work/stage1/x1/lvl2-digest.txt`).

## 9.5 Card sizes

What happens depends on the size of the card:

- **GS 512 KB (15 pages).** In music mode, every level change resets the card and uploads the module and the 10 FX
  again. In effects-only mode, the first `#23` patches the driver (9.2). The jingle, the 10 FX and the 11 disk FX are
  then loaded once, as handles 1-22, and FX numbers shift by one. The `$61A8` upload becomes a jump to `$61B7`, so it
  only plays.
- **GS 128 KB (3 pages, 96 K for samples at card RAM `$08000-$1FFFF`).** The load-once path is never taken. Nothing
  checks the free memory, and the firmware keeps writing past the end of the RAM. In the emulator, the writes wrap to
  card RAM `$00000`:
  - **Music mode, level 1.** The module occupies `$08000-$167FF`. FX 1-7 fit, and FX 8 is cut at `$20000` after
    9436 bytes. The rest of FX 8, and FX 9 and 10, land at `$00000-$02D61` (`work/images/play-music-gs128/`). The
    card kept running and playing.
  - **Effects-only mode.** The 21 FX need 102866 bytes. FX 21 is cut at 4582 bytes, and 4562 bytes wrap to
    `$00000` (`work/images/play-fx-gs128/`).
  - **Other levels.** A module larger than 47774 bytes overflows the same way in music mode. That is the case for
    levels 1, 5, 7, 9 and 12, as worked out from the sizes; only level 1 was run.

  In the emulator, card RAM `$00000-$07FFF` is the page whose upper half is the firmware's fixed `$4000-$7FFF`
  window. The wrapped bytes fall in its lower half. Two things are open for stage 2: what the firmware keeps there,
  and whether a real 128 KB card aliases the same way.

## 9.6 The beeper

Zynaps's beeper player `$B30C` is still there and still called every frame (`$AC76`). But no sound reaches it: the
only request routine, `$B2F0`, is now the `$C018` stub, and the sound-0 call at `$ABF1` is removed. In the music play,
port `$FE` received 53334 writes from 14 call sites, and the effects-only play gave the same picture. Every write was
`$00`, so no write had bit 4 set. The player's `OUT` at `$B35E` ran 0 times. The beeper code is present but silent.
The other `OUT ($FE)` sites (`$86D7`, `$8FBD`, `$949C`, `$A535..$A573`, `$AA91`, `$AACA`, `$ABD7`) write black
border and silence (`work/stage1/x1/hook1-counts.txt`).
