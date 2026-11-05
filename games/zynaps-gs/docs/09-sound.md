# 9. Sound

What this covers: the General Sound card and what the game asks of it, the driver in bank 1, the media (13
Protracker modules and 22 sampled effects), where the game makes each sound and which game event it marks, what
happens on a 128 KB card, and the beeper code left behind. The runs it rests on (`work/stage1/NOTES.md`,
`work/stage2/h2/`):

- `x1`: Pentagon 128 with a GS 512 KB, in music mode and in effects-only mode (stage 1);
- `x2`: Pentagon 128 with a GS 128 KB, in both modes (stage 1);
- `h2`: the effects-only game of `x1/fx2-game.szx` played 60000 frames with the ship invulnerable (POKE 65495,1,
  the 48K's switch `$FFD7`) by `work/stage2/hooks2.py`, through levels 1, 2, 3, 7, 8, 6, 4, 9, 5 and into 10 (this
  game's order); three 6000-frame runs with the side weapon poked (player record +8: 2 plasma, 3 homing missiles,
  4 seeker) and one 4000-frame run with the ship mortal;
- `x3`: GS 128 KB again, the card's memory read and FX 7-10 rendered (stage 2, 9.5).

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
| `#45` / `#39` | FX default volume, play FX | ShotSound in music mode with SHOOTING NORMAL |
| `#41` | FX volume | SaturnSound |
| `#3A` | stop FX (mask) | in StopAll, which has no caller |
| `#48` / `#49` | FX loop points | in SetLoopStart / SetLoopEnd, which have no callers |

The menu chooses between two modes. Key 1 is "START MUSIC & EFFECTS" and key 2 is "START ONLY EFFECTS". The choice is
the flag `$B486`: 0 means music, 1 means effects only. In both modes the title page plays the title module (level
13). In play, the music mode has a module and 10 effects. The effects-only mode has no module and 21 effects.

## 9.2 The driver (bank 1 `$C000`)

The driver's source is `src/disk/driver/` (from `src/disk/driver.ann`, every entry named); the names below are its
labels, the addresses the bank 1 ones.

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
| 1 | 650 | bank 1 `$FAA5` | PodAppearsSound |
| 2 | 5207 | bank 1 `$FD2F` | NextWeaponSound |
| 3 | 5006 | bank 3 `$D186` | WeaponOnSound |
| 4 | 1396 | bank 3 `$E514` | EnemyFireSound, PlasmaLaunchSound |
| 5 | 6308 | bank 3 `$EA88` | MissileLaunchSound |
| 6 | 1347 | bank 4 `$C32C` | PlasmaBounceSound |
| 7 | 9562 | bank 4 `$C86F` | ExplosionSound, BigEnemyDestroyedSound |
| 8 | 10679 | bank 4 `$EDC9` | ShipExplodesSound, BigEnemyDestroyedSound |
| 9 | 3827 | bank 6 `$D780` | ShotSound |
| 10 | 6548 | bank 6 `$E673` (its last 7 bytes come from bank 7 `$C000`, zeros) | ShotSound |
| 11-12 | 11282, 4216 | blob 321 (raw) | BigEnemyDestroyedSound; BigEnemyHitSound |
| 13-16 | 3450, 3554, 2516, 4464 | blob 382 (Trush blk05) | BigEnemyHitSound (13, 14); SceneryBounceSound; Path682CSound |
| 17-20 | 4589, 1442, 3532, 4147 | blob 429 (raw) | DiveSound; ArenaBounceSound; Path6850Sound; PathSound, Path685BSound, Path68F9Sound |
| 21 | 9144 | blob 483 (Trush blk06) | SaturnSound (it is bytes 13318-22461 of sample 8 of level 7's module, sign flipped) |

FX 11-21 are on the card only in effects-only mode, and only effects-only code asks for them: every entry that
plays one is reached through CallDriverFx, which calls the driver only in effects-only mode, except
BigEnemyDestroyedSound, whose music-mode branch plays FX 8. So music mode never sends an FX number the card does not
have.

**Modules.** All 13 are Protracker `M.K.` with 31 samples. They are rendered in full by openmpt123 to
`work/audio/mod/levelNN.flac`, and their names are in [texts/modules.md](texts/modules.md).

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

All the sites are patched by the installer (3.5). Zynaps's beeper request `$B2F0` took the sound number in A; the
GS points the six request sites at stubs of their own and turns `$B2F0` itself into ObjectSoundStub. The game event
of each site is the 48K's routine it sits in (`src/game/game.ann`), and each was seen to fire in play.

"Seen" is the h2 count: the effects-only play with the ship invulnerable (60000 frames, levels 1-9 and part of 10;
the per-level counts: `work/stage2/h2/summary.txt`), the weapon runs (`weapon02/03/04.tsv`) and the mortal run
(`mortal.tsv`). The memory profiler counts the executions of each stub. Music mode reaches the same stubs; the
effects-only entries (CallDriverFx) then return at once.

| Zynaps site (routine) | Game event | Stub → driver entry | Sound | Modes | Seen (levels) |
| --- | --- | --- | --- | --- | --- |
| `$A31D` (ExplosionToPod) | a weapon pod appears | PodAppearsHook → PodAppearsSound | FX 1, note `$26` | both | 63 (all) |
| `$A226` (PodStep) | the pod selects the next weapon | NextWeaponHook → NextWeaponSound | FX 2, note `$32`+r&3 | both | 1 (7) |
| `$A21F` (PodStep) | a weapon switched on | WeaponOnHook → WeaponOnSound | FX 3, note `$32` | both | 25 (all but 8) |
| `$A1C4` (EnemyFire) | an enemy fires | EnemyFireHook → EnemyFireSound | FX 4, note `$30`+r&1 | both | 928 (all) |
| `$9CA6` (PlasmaFrame) | a plasma ball launched | PlasmaLaunchHook → PlasmaLaunchSound | FX 4, note `$2A`+r&1 | both | 3 (plasma run) |
| `$9CFA`, `$9D1F` (HomingFrame, SeekerFrame) | a homing missile or a seeker launched | MissileLaunchHook → MissileLaunchSound | FX 5, note `$32`+r&1 | both | 9 (seeker run; the homing missile did not launch in 4750 frames) |
| `$9EA5` (PlasmaHandler) | a plasma ball bounces | PlasmaBounceHook → PlasmaBounceSound | FX 6, note `$3C`+r&1 | both | 3 (plasma and seeker runs) |
| `$9C77` (FireLaser) | a laser shot | ShotHook → ShotSound | FX 9 note `$34` (laser level 0-1) or FX 10 note `$32` (2-3), +r&1; none with SHOOTING DISABLED | both | 135 (all) |
| `$ABF1` | beeper sound 0 | removed (`NOP`s) | none | | |
| `$9B51` (PlayerHandler) | the ship hit | ShipHitHook → ShipExplodesSound | FX 8, note `$2D`, not gated | both | 8 (mortal run; never with `$FFD7` set) |
| `$9FBE`, `$A034` (EnemyDies, LockableDies) | an enemy explodes | ExplodeHook → ExplosionSound | FX 7, note `$2C`+r&3 | both | 255 (all) |
| `$95E7` (PathOpBounce) | an enemy bounces off the scenery (moving down: D bit 7 clear) | SceneryBounceHook → SceneryBounceSound | FX 15, note `$2D`+r&1 | effects only | 263 (3, 7, 9) |
| `$A0BA` (BigEnemyHandler) | a big enemy hit, not destroyed | BigEnemyHitHook → BigEnemyHitSound | levels 7 and 11: FX 12, note `$2C`+r&1; else FX 13 or 14, note `$31`+r&1 | effects only | 58 (7, 8, 9, 5) |
| `$A0D5` (BigEnemyHandler) | a big enemy destroyed | BigEnemyDestroyedHook → BigEnemyDestroyedSound | music: FX 8 as ShipExplodesSound; effects only: FX 11, 8, 7 and 11 in the four channels at once | both | 1 (5) |
| `$9823` (PathOpBounceArena) | an enemy bounces off the arena's edge | ArenaBounceHook → ArenaBounceSound | FX 18, note `$3A` | effects only | 58 (7, 8, 6) |
| `$9856` (PathOpDive) | an enemy starts a dive | DiveHook → DiveSound | FX 17, note `$3C` on level 4, else `$28` | effects only | 25 (8, 4, 9, 5) |
| `$969D` (PathOpAimPlayer) | an enemy aims at the ship | AimPlayerHook → PathSound | by the path pointer: `$6850` (path 4 + 4) or E = `$EE`: FX 19; `$6846` (path 3 + 4): FX 20 | effects only | 87 calls (7, 8, 6, 9, 5, 10) |
| `$9694`, `$9747` (the path movers) | an enemy moves on its path | ObjectSoundStub (`$B2F0`) → ObjectSound, then PathOpAccelerate | by the path pointer and the frames left: path 2 + 6 with 10 left: FX 16; path 23 + 5 with 18 left or path 5 + 5 with 17 left: FX 20; else SaturnSound (SATURNS on: path 1's objects, FX 21, `#41`, at most once in 8 calls a slot, only when the movement changed), else PathSound | effects only | 48467 calls (all) |
| `$9954` | an object's slot freed | SlotGoneHook → ClearSlot | none: the SaturnSound slot cleared | effects only | 681 (all) |
| `$B075` (SetLevelStart) | the next level chosen | NextLevelHook | NextLevel = B; no sound | both | 9 (each level done) |
| `$B03E` | the round start | RoundStartHook → LevelChange | loads the level's module and FX when the level changed | both | 9 |
| `$AF51` | PREPARE FOR COMBAT | GameStartHook → LevelChange (LoadKind 1) | the start jingle | both | 9 |
| `$B102` (EndOfPlay) | the wait between rounds | WaitStub (`$A6AE`) → RoundWait | music: the module fades out on end code 2 (the level done); else a fixed delay | both | 9 |
| `$B203` (MainLoopTitle) | the title pages | TitleEntry | the title module loaded once (LoadKind 2) | both | |

In music mode a round start after a level done resets the card and uploads the next level's module and the 10 FX.
The level change itself was first proved in stage 1 by poking (`$B462`) = 2 before a death: the next round start
sent `#23`, `#F3`, the jingle, level 2's module (42496 bytes, identical to `level02.mod`), the 10 FX and `#2A $20`
(`work/stage1/x1/lvl2-digest.txt`).

All 12 driver places that never fired in stage 1 fired here, and the six beeper request sites as well. What the
plays could not show: FX 12 (levels 7 and 11 only: level 7 had a single big-enemy hit, level 11 was not reached in
60000 frames), the music-mode branch of BigEnemyDestroyedSound, the homing missile's launch (MissileLaunchSound fired for
the seeker) and which of the path sounds (FX 16, 19, 20) actually played: the stubs were counted, not the FX the
entries chose.

## 9.5 Card sizes

What happens depends on the size of the card. The driver asks the card's page count (`#23`) at each level change.

- **GS 512 KB (15 pages).** In music mode, every level change resets the card and uploads the module and the 10 FX
  again. In effects-only mode, the first `#23` patches the driver (9.2). The jingle, the 10 FX and the 11 disk FX are
  then loaded once, as handles 1-22, and FX numbers shift by one. The `$61A8` upload becomes a jump to `$61B7`, so it
  only plays.
- **GS 128 KB (3 pages).** The load-once path is never taken: every level change uploads again. The card has room
  for all of it, and nothing is overwritten.

Stage 1 saw the uploads on 128 KB run past card RAM `$1FFFF` and land at `$00000`, and took it for a wrap. It is the
firmware's own layout. Its RAM test (`INIT_L.a80`, `INITR01`-`INITR0E`) writes each page's number at its `$FFFF` and
reads them back: on 128 KB pages 2, 3 and 4 are whole, and page 1 is the one whose upper half is the fixed `$4000-$7FFF`
window, the firmware's own work memory (the test sees it through `$7FFF`). The firmware lists the whole pages in
`RAMPG` and puts page 1 after them as a last, half page: the loader (`LOAD_L.a80`) fills it only up to `$BFFF` (card RAM
`$00000-$03FFF`) and from there on reads the bytes and drops them. Read from the card (`work/stage2/x3`, music mode,
level 1): `RAMPG` = `02 03 04 01`, `NUMPG` = 3. So the room for samples is 96 K + 16 K = 112 K (114688 bytes), from
card RAM `$08000` on, then `$00000-$03FFF`.

| Load (music mode: the module + FX 1-10, 50530 bytes) | Bytes | Fits in 114688 |
| --- | ---: | --- |
| level 1 (the largest module, 59392) | 109922 | yes, 4766 left; FX 8 is split across `$1FFFF` / `$00000`, FX 9 and 10 at `$004DB-$02D61` |
| levels 5, 7, 9, 12 (56320, 54016, 53910, 48128) | 99058 or less | yes |
| the title (module 13 alone) | 51456 | yes |
| effects only: the 21 FX | 102866 | yes; FX 21's last 4562 bytes at `$00000` |

Every level fits; none breaks. The firmware never writes past its half page, so a larger load would lose its tail,
not overwrite the work memory. The bytes in the half page were checked against the effect files (`work/stage2/x3`):
FX 1-7 whole in pages 2-4, FX 8 split, FX 9 and 10 whole in the half page. Rendered on the card from there
(`work/audio/gs128/fx07..fx10-*.wav`, the card alone, 1.6 s each after `#32` stopped the module), all four play: RMS
0.070 / 0.062 / 0.021 / 0.067 (left), dominant 368 / 396 / 148 / 90 Hz. FX 7, which lies in an ordinary page,
differs from its 512 KB render (`work/audio/fx/`, made in effects-only mode) as much as FX 8-10 do (1.2-1.6 times the
level, 5-16 % in the dominant frequency): the renders differ by mode, not by where the bytes lie. The split FX 8 and
the FX in the half page play like the others. A real 128 KB card does the same: the layout is found by the ROM's RAM test,
not set by the emulator, and on the card's schematic the fixed window is the upper half of RAM page 1
(`gs-tdd.md` 2.1 in the unreal-ng GS design notes).

## 9.6 The beeper

Zynaps's beeper player `$B30C` is still there and still called every frame (`$AC76`). But no sound reaches it: the
only request routine, `$B2F0`, is now the `$C018` stub, and the sound-0 call at `$ABF1` is removed. In the music play,
port `$FE` received 53334 writes from 14 call sites, and the effects-only play gave the same picture. Every write was
`$00`, so no write had bit 4 set. The player's `OUT` at `$B35E` ran 0 times. The beeper code is present but silent.
The other `OUT ($FE)` sites (`$86D7`, `$8FBD`, `$949C`, `$A535..$A573`, `$AA91`, `$AACA`, `$ABD7`) write black
border and silence (`work/stage1/x1/hook1-counts.txt`).
