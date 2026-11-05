# 9. Sound

What this covers: how the conversion replaces Nether Earth's beeper with the General Sound card: the module and the
effects it uploads, the GS firmware commands it uses, the driver in bank 1 that turns the game's sound calls into
GS effects, and every place in the game that calls it. NE's own engines (the menu tune, `SoundEffect`, `Beep`) are
described in [NE 09](../../nether-earth/docs/09-sound.md); this document says only what changed.

Stage 1 draft. It rests on the static listings of `neart001`, `neart021`, `neart022` (stage 1 NOTES 1) and the live
runs of stage 1 NOTES 2 (Pentagon 128 in unreal-ng; `x1` SCL + NeoGS, `x2`/`x3` SCL + GS 512 KB, `x4` TAP from 128
BASIC, `x6` TAP from 48 BASIC via `USR 0` with a bot game of 9000 frames, `x8` the same on NeoGS).

## 9.1 The design in one paragraph

The conversion keeps NE's code at NE's addresses (542 of NE's 563 entries byte for byte, [02](02-architecture.md))
and silences the beeper: the six `OUT ($FE),A` of the menu tune's tone loops and drums are `NOP NOP`, so the tune
still runs (and still times the menu) but makes no sound. Instead the loader uploads one ProTracker module and 14
effect samples to the GS before the game starts, starts the module playing and leaves it playing for the whole game:
the menu, play and the construction screen share one endless tune. The game's three sound routines (`Beep`
`$CCAC`, `SoundEffect` `$D5C4`, `NuclearRumble` `$BAEE`) and the entry of `ConstructionMenu` `$C849` now call a
small driver in RAM bank 1 at `$C000`, which picks a GS effect for each game sound and starts it with the GS ROM's
effect player. No GS program is uploaded: everything the card does is its ROM's module and effect player.

## 9.2 What is on the card

What the loader means to upload, in this order (the GS assigns the handles in load order: module 1, effects 1-14).
What really lands on the card differs between the disk and the tape loader; see the end of this section.

| GS object | File(s) | Bytes | Contents | Played for |
| --- | --- | ---: | --- | --- |
| module 1 | `neart002`-`neart006` | 138 070 | ProTracker `M.K.`, "_desert dream vol.2": "song composed by laxity / kefrens in the year 1993, ripped from the demo "desert dream" by sven g., original format: "laxity tracker", converted with "pro wizard 1.5"" (the sample names); 26 samples, 36 positions, 29 patterns, restart position 2 | always, from the load on |
| effect 1 | `neart007` | 14 798 | 8-bit unsigned PCM (every effect) | id 1, id `$C8` (`StartRobot`'s last beep) |
| effect 2 | `neart008` | 14 592 | | id 2 (a robot destroyed): never chosen (9.4) |
| effect 3 | `neart009` | 23 296 | | id 2, R `$00-$50` |
| effect 4 | `neart010` | 19 456 | | id 2, R `$51-$7F` |
| effect 5 | `neart011` | 26 880 | | id 3 (the construction menu opens) |
| effect 6 | `neart012` | 8 499 | | id 4 (a shot fired), R `$00-$50` |
| effect 7 | `neart013` | 15 427 | | id 4, R `$51-$7F` |
| effect 8 | `neart014` | 19 187 | | id 4: never chosen (9.4) |
| effect 9 | `neart015` | 9 056 | | id `$78` (menu confirm) |
| effect 10 | `neart016` | 176 | | id `$14` (menu click) |
| effect 11 | the first 401 bytes of `neart019` | 401 | meant to be `neart017` (401 bytes), see 9.5 | id `$64` |
| effect 12 | `neart018` | 15 849 | | id `$50` |
| effect 13 | `neart023` | 12 560 | | id `$0A` (a shot ends: a miss or a hit) |
| effect 14 | `neart019` + `neart020` | 49 274 | one sample over two files (the stream left open between them) | id 9 (the nuclear blast) |

The module and the effects take 367 521 bytes (359 KB): more than the 128 KB of a stock General Sound. The game needs
a card with 512 KB (an expanded GS) or a NeoGS (9.6).

**The samples' sign.** The GS firmware keeps samples unsigned: `COM30`'s module loader adds `#80` to every MOD sample
after the load (`PLAY.a80`, `SMPMD1`), and `LOAD` adds C to each byte it stores. `#3E` with data 1 jumps to `COM38`
(C = 0: stored as sent, for unsigned samples); with data 0 it sets C = `#80` (for signed samples). The effect files
are unsigned: the mean step between neighbouring bytes, read as unsigned, is 1.2-15 against 3.9-138 read as signed
(stage 1 NOTES 2.4).

- **The disk loader** sends data 0 for all 14: every effect it loads is stored with its top bit flipped and plays as
  a harsh, loud distortion of itself.
- **Hood's tape loader** sends data 1 for effects 1-13 (stored right) and data 0 for effect 14 (flipped).

Rendered on the card from the tape load: `work/audio/tap-fx01.wav` (effect 1 as stored) against
`tap-fx01-as-signed-like-disk.wav` (the same bytes flipped, as the disk stores them). The AC level goes from 825 to
3434, and the step-to-level ratio from 0.096 to 0.19. Effect 14 as the tape stores it (`tap-fx14.wav`, ratio 0.321)
against unflipped (`tap-fx14-as-unsigned.wav`, 0.102).

**What the disk loader really leaves on the card.** The GS has one latch per direction. A command written while the
card has not yet taken the previous one replaces it. The disk loader never waits (9.3), and two of its writes are lost
that way (live run `x3`, the `zxbus.1` history; host writes in `work/stage1/scl-host-gs-writes-*.txt`):

- `#F4` makes the card restart cold (`COMF4`: `JP 0`, then the ROM's RAM test, frames 556-678). The `#30` and `#D1`
  written in the same frame are gone. The 138 070 module bytes stream into nothing, and the card takes the closing
  `#D2` as an unknown command. **No module: the disk version plays no music.**
- In 5 of the 14 effect loads the card was still busy when `#3E` and then `#D1` came a few T-states apart. `#D1`
  replaced `#3E`, and the effect was skipped (frames 1400, 1588, 1732, 1804, 2250: effects 3, 5, 7, 8 and 14).

The card ends with `CNTMOD` = 0 and `CNTFX` = 9: `neart007`, `008`, `010`, `012`, `015`, `016`, `019` (401 bytes),
`018` and `023` as handles 1-9. The driver's numbers no longer match: id 3 (the construction menu) plays handle 5
= `neart015`, id `$78` plays handle 9 = `neart023`, and ids `$14`, `$64`, `$50`, `$0A`, 9 ask for handles 10-14,
which the card refuses (`COM39_9`). Which of the `#3E` are lost depends on the card's timing. The cold restart is the
GS ROM's own, so real hardware with this ROM should lose the module the same way. Stage 2 can check whether another GS
ROM restarts faster.

**The tape loader** waits after every command (9.7): `x4`, `x6` and `x8` end with `CNTMOD` 1, `CNTFX` 14,
`MODVOL` `$25`, `FXVOL` `$40`, and the module playing (`work/audio/tap-menu-module-30s.wav`).

## 9.3 The GS commands used

All are commands of the GS ROM's command interpreter (firmware sources in unreal-ng
`docs/inprogress/2026-09-19-general-sound/materials/gs/gs-firmware/firmware/src`, the dispatch table `COMTABH` in
`TABLES_H.a80`). A parameter goes to the data port `$B3` before its command goes to `$BB`.

| Command | Data before it | Firmware | Meaning | Who sends it |
| --- | --- | --- | --- | --- |
| `#F4` | | `COMF4` | reset the card's software (clear modules and effects) | loader, `$61BE` |
| `#30` | | `COM30` | load a module: the bytes that follow on `$B3` until a command | loader, `$61C2` |
| `#D1` / `#D2` | | `LOAD` | open / close the data stream of a load | loader |
| `#3E` | `0` | `COM3E` -> `COM38_` | load an effect (unsigned samples, LX = `#80`): the bytes that follow until a command | loader, `$6317` / `$6352` |
| `#31` | `0` | `COM31` | play the module (0: the current one) | loader, `$62DF` |
| `#2B` | `$40` | `COM2B` | effects' master volume = 64 (full) | loader, `$62CC` |
| `#2A` | `$25` | `COM2A` | module's master volume = 37 of 64 | loader, `$62D4` |
| `#40` | `$2F` | `COM40` | the note of the current effect (`CURFX`) = 47 | driver, `$C0E8` |
| `#39` | effect | `COM39` | play effect N (it becomes `CURFX`) | driver, `$C0F0` |

The disk driver sends `#40` before `#39`: the note goes to the effect played last, not to the one about to play. Every
call sets 47, so after an effect has played once its note stays 47; its first play uses the note it was loaded with.
Hood's tape driver selects the effect first (`#2E`, `COM2E`) and waits for the card to take each command (9.7).

## 9.4 The driver (`neart021`, bank 1 `$C000`)

The game reaches it through two new routines in NE's spare zeros `$A56A-$A5FF`:

- `GsSound` `$A583`: DI, save every register, page RAM bank 1 at `$C000` (`OUT $7FFD,$11`), `CALL $C000` with A = the
  game's sound id, page bank 0 back (`$10`), restore, EI.
- `GsMenuSound` `$A569`: the same with A = 3, ending with `LD IY,$DA00` (the instruction of `ConstructionMenu` it
  replaced) and EI.

The driver at `$C000` compares A against a list (`CP n` / `JR NZ`) and plays one effect:

| Game id | GS effect | Notes |
| --- | --- | --- |
| 1 | 1 | no caller found in stage 1 |
| 2 | 3 or 4 (2 never) | chosen from the R register: windows `$01-$50` -> 3, `$51-$A0` -> 4, `$A1-$FF` -> 2, 0 -> 3. R's bit 7 changes only by `LD R,A`: the game, the loaders and the drivers have none, the 48K and 128K ROMs have none, and TR-DOS's three (`$2AE1`, `$2B1C`, `$2EBF` of `trdos.rom`) put back an R it read itself. So R stays `$00-$7F`: effect 3 for 81 of its 128 values, 4 for 47, effect 2 never |
| 3 | 5 | |
| 4 | 6 or 7 (8 never) | as id 2: 6 for R `$00-$50`, 7 for `$51-$7F` |
| `$78` | 9 | a second `CP $78` (-> effect 1) further down is never reached |
| `$14` | 10 | |
| `$64` | 11 | |
| `$50` | 12 | |
| `$C8` | 1 | |
| 9 | 14 | |
| `$0A` | 13 | |
| anything else | none | the driver returns silently |

The play itself (`$C0E7`): `OUT ($B3),$2F`, `OUT ($BB),#40`, `OUT ($B3),effect`, `OUT ($BB),#39`, with no wait for
the card in between.

## 9.5 Every call of the sound

`python3 tools/sound_calls.py work/tmp/neart001-64k.bin work/media/scl/files/neart021.C` (stage 1 NOTES 1;
`work/stage1/sound-calls.txt`). `Beep` keeps its callers and its A (NE's half-period delay) but now only does
`CALL GsSound`: A is the sound id, and a value the driver does not list is silent.

| Call | In (NE name) | Id | GS effect | The event (NE docs) |
| --- | --- | --- | --- | --- |
| `$A803` | `RobotMenuChoose` | `$78` | 9 | a robot menu choice |
| `$A96D` | `DirectControl` | `$78` | 9 | |
| `$AA06` | `OrdersMenuChoose` | `$78` | 9 | |
| `$AAB3` | `DistanceShow` | `$14` | 10 | |
| `$AAC6` | `DistanceShow` | `$78` | 9 | |
| `$ABF7` | `SetOrder` | `$78` | 9 | |
| `$ACD0` | `CombatMenuCode` | `$FA` | none | silent (NE's low buzz) |
| `$AD17` | `ListMenu` | `$14` | 10 | the cursor moves |
| `$AD37` | `ListMenu` | `$64` | 11 | a choice |
| `$AEEC` | `GameOverWait` | `$FA` | none | silent |
| `$BAF1` | `NuclearRumble` | 9 | 14 | each burst of the nuclear blast |
| `$C284` | `LoadError` | `$FA` | none | silent |
| `$C849` | `ConstructionMenu` | 3 | 5 | the construction menu opens |
| `$CA91` | `ConstructionMenuLoop` | `$64` | 11 | |
| `$CAAE` | `ConstructionMenuLoop` | `$78` | 9 | |
| `$CB47` | `MoveMenuCursor` | `$14` | 10 | |
| `$CB83` | `StartRobot` | `$50`, `$4B` ... `$19`, `$14` | 12, none ..., 10 | NE's falling sweep: only its first and last steps sound |
| `$CB90` | `StartRobot` | `$C8` | 1 | the robot leaves the factory |
| `$D5CA` | `SoundEffect` | 4 | 6 / 7 / 8 | `SoundFx` 2: a shot fired |
| `$D5D9` | `SoundEffect` | `$0A` | 13 | `SoundFx` `$FD`: a miss |
| `$D5E5` | `SoundEffect` | 2 | 3 / 4 / 2 | `SoundFx` `$C9`: a robot destroyed |

`SoundEffect` now plays once per event: it clears `SoundFx` (`$FD53`) to 0 after each id it sends. `PlayInterrupt`
still counts a non-zero `SoundFx` up each frame, and a value `SoundEffect` does not list is left to count. A hit
(`$FA`) counts through `$FB` and `$FC` to `$FD` and then plays the miss sound, two frames late. Live check (`x6`,
`SoundFx` poked during play, host writes in `work/stage1/x6/fx-ports.jsonl`): `$01` -> effect 6, `$FC` -> 13,
`$FA` -> 13, `$C8` -> 3.

In the 9000-frame bot game of `x6` (`work/stage1/tap-host-gs-commands.txt`), the driver sent 102 effects:

- 57 x effect 10 and 26 x effect 11 (menu cursor and choice);
- 8 x effect 9;
- 4 each of effect 5 (construction menu), effect 12 and effect 1 (a robot started).

No fight came in 9000 frames; the shot and kill sounds come from the pokes.

`Beep` used to take 256 half-periods of A x 13 T-states or so; now it returns at once (or after the driver's few
hundred T-states). Every pause NE made with a beep is gone: menu cursors move as fast as the keys repeat (to check
in stage 2 against the recordings).

## 9.6 The machine it needs

| Machine | Card | Disk (SCL / TRD) | Tape (Hood) |
| --- | --- | --- | --- |
| Pentagon 128, TR-DOS | GS 512 KB | loads, plays; no music, 9 effects on wrong ids, the rest silent (9.2) | — |
| Pentagon 128, TR-DOS | NeoGS 2 MB | silent at the menu (`x1`, capture rms 0), as with no module; its variables were not read in stage 1 | — |
| 128K, 48 BASIC via `USR 0` | GS 512 KB | — | music and all 14 effects (`x6`) |
| 128K, 48 BASIC via `USR 0` | NeoGS | — | music and all 14 effects (`x8`, `work/audio/tap-neogs-menu-10s.wav`) |
| 128K, 128 BASIC or Tape Loader | any | — | loads with music, then hangs at the first sound in play (9.7) |
| 128K, 48 BASIC from the 128 menu | any | — | the same hang |

The game itself is 48K code plus one RAM page for the driver. The card needs 367 521 bytes: a 512 KB GS or a NeoGS.
The loading screen `neart000` says so itself: "GS-512" under the title, "TRON 2002" in the corner
(`work/stage1/screens/scl-00-loading-screen-neart000.png`).
A 128 KB GS was not run: its `NUMPG` is 3, and the uploads would run past its memory.

## 9.7 The tape version (Hood, 2017)

Hood's driver (`neart021` on the tape, 271 bytes, loaded into bank 6) keeps the id table and replaces the play
routine: `OUT ($B3),effect`, `#2E` (select the current effect), `OUT ($B3),$2F`, `#40` (its note), `OUT ($B3),effect`,
`#39`, and after every command a wait until the card has taken it (`IN A,($BB)` / `RRCA` / `JR C`, the
`SendGsCommand` at `$C0F8` takes the command byte inline after its `CALL`). The note now reaches the effect that
plays, and the commands cannot overrun the card. His BASIC also loads `neart017` for effect 11 and offers
"2-music OFF", which pokes `RET` at `$62DF` so the module is never started.

Further tape-only details:

- The loader also sends effects 1-13 as unsigned (`#3E` data 1) and effect 14 as signed (9.2).
- **The driver only reaches bank 6 when paging is free under the 48K ROM.** The BASIC runs `USR 25254`, which
  ends by paging bank 6 (`$62AF`: `OUT ($7FFD),$16`). Then it runs `LOAD "neart021" CODE` to `$C000`, then
  `USR 25273`, which pages bank 0 back.
  - Under 128 BASIC (Tape Loader or 128 BASIC), the ROM restores `BANKM` (bank 0) on its way into the tape loader.
  - From the 128 menu's "48 BASIC", the paging is locked (bit 5).
  - Either way the driver lands in bank 0 under the game, and bank 6 stays zeros (`work/images/tap-via128basic-menu-bank6.bin`).
  - The game then loads, the module plays at the menu, and the first sound in play pages bank 6 and calls `$C000`:
    zeros run to `HALT` with interrupts off (`x4`: PC `$FFFA`, `iff1` 0).
- From 128 BASIC, `PRINT USR 0` gives a 48 BASIC with paging free, and the tape plays through (`x6`,
  `work/images/tapusr0-menu-bank6.bin` holds the driver at `$C000`).
