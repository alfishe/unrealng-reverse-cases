# 9. Sound

Draft (stage 1): the two players, the engine's entries and which game event starts which effect. The formats and
the tune charts come with stage 3.

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - the tune as a chart -->
<!-- - a routine animation of the player -->

The recordings it rests on: `c1` (Pentagon 128, random play from frame 3902 to 13702: five games to their end and a sixth); the WAV files
`work/stage1/audio/intro-tune.wav` and `play-fire.wav` (12 s each, from `work/stage1/explore/title.szx` and
`play.szx`, `work/stage1/audio/capture.py`; written to files, never played).

## 9.1 Two players

| | The intro | The game |
| --- | --- | --- |
| Where | `$8000` (copied from block 1 `$D810`) | page 4 `$C968`-`$CD22`, data `$DE48`-`$FE6F` |
| Player | STarKos (Targhan / Arkos, a CPC tracker's player): `$8000` init with DE = the song, `$8003` play, `$8006` stop | a CPC-style three-channel driver with effects: `$C968` start the music, `$C96B` stop, `$C96E` play each frame, `$C971`-`$C9B1` start an effect |
| Song | `SK10` at `$8990` | sounds `$0B`, `$0C`, `$0D` (the music's three channels) and effects `$0E`-`$1F`; pointer table at `$DF4D` |
| Periods | `$8625`, 84 entries from 3822: the CPC's table for its 1 MHz AY, unchanged | `$DE62`, 82 entries from 4126 |
| AY | ports `$FFFD` / `$BFFD` | `OUTD` of a register image from `$CC98` |

- The STarKos table is the CPC's own (3822 = C0 at 1 MHz). On the 1.75 MHz ZX AY the same periods sound 1.75 times
  higher (about 9.7 semitones), unless the song was transposed when it was converted. The intro capture's dominant
  frequency is 546 Hz. Whether the tune sounds in the CPC's key needs the CPC original to compare (stage 3).
- No signature in the base matches either player (both new to the base).
- The effects alternate between channels by `XOR` of `$CC9B`; the channel records are at `$CC9C`, `$CCC9`, `$CCF6`.

## 9.2 Which event starts which effect

The 128K glue replaces the 48K game's beeper calls (`CALL $B2F0` with A = the beeper sound, and a few other calls)
with calls to 15 hook stubs at `$B32F`-`$B3A8`. Each stub loads L with an engine entry, jumps to the shared stub at
`$B30D` (page 4, `CALL $C9xx`, page 0), then does what the site did. The event names come from the 48K code around
each site (`work/stage1/dis/game48-static.asm`) and from screenshots at the frames each stub ran in `c1`
(`time_travel coverage_scan`, `work/stage1/stub-frames.txt`; shots in `work/stage1/screens/events/`).

| Site | Stub | Entry, sounds | Runs in `c1` | The event |
| --- | --- | --- | --- | --- |
| `$9C77` | `$B32F` | `$C971`: `$0E` | 91 | the player fires: `$9C1D` takes a free shot slot of four (`$F4F8`, `$2C` each) and places it at the ship (48K beeper sound 2) |
| `$A29F` | `$B386` | `$1D` | 43 | an explosion starts: `$A293` sets an object's explosion frames (`$FD00`, `$EDB2`, `$D6ED`); alone 25 times (an enemy destroyed), 18 times with `$B354` |
| `$9BFF` | `$B354` | `$14` + `$15` | 18 | the player's ship destroyed: three times per game, the game over after the third (`c1` 4351, 4626, 5055, game over 5165; six games, the sixth cut by the recording's end), with the explosion `$1D` in the same frame |
| `$A1C4` | `$B374` | `$19` | 6 | an enemy fires a missile aimed at the ship (`$A14F` copies the firer's place, aims at `$F36C`; 48K sound 1) |
| `$A31D` | `$B381` | `$1C` | 4 | a fuel pod (spore) changes state: an object becomes the pod sprite `$7EBB`, the pod bits move in `$80BD`/`$80BE` (48K sound 4); to name exactly in stage 3 |
| `$A21A` | `$B379` | `$0F` | 1 | the ship takes a pod with the power gauge full (`$8184` ≥ 8: score `$80F0` instead; 48K sound 6) |
| `$A247` | `$B364` | `$16` | 1 | a pod taken: `$81C5` bit 2 set (same frame as `$B379` in `c1`, 12017) |
| `$A5D1` / `$A7F7` | `$B39C` | `$1E` + `$1F` | 5 | the game over: the screen wipe before the role of honour (once per game) |
| `$A81B` | `$B344` | `$12` | 5 | the role of honour shown (18 frames after the wipe) |
| `$A8B7` | `$B34C` | `$14` + `$15` | 5 | the role of honour's result (2 frames later; `UNRANKED` in all five) |
| `$ACA2` | `$B334` | `$0F` + `$10` | 0 | not seen: after `$ACA2`'s level count (`$800F` table, `INC (IX+12)`); to find in stage 3 |
| `$9EC2` | `$B33C` | `$11` | 0 | not seen: an object's countdown (`DEC (IY+38)`) before `$99A9` |
| `$9CFA` | `$B35C` | `$1A` + `$1B` | 0 | not seen: an object launched from the ship's place (`$9CB0`, `(IX+38)` = `$4B`), likely a weapon |
| `$9CB0` | `$B36C` | `$18` | 0 | not seen: the weapon slot `$F5A8` launched from the ship's place |
| `$A7BB` | `$B38F` | `$1E` + `$1F`, the music stopped first | 0 | not seen: in the routine next to the game over's (`$A79F`-`$A7F6`), likely the end of the game won |

Five events never happened in `c1` (the play was random keys over short games): a second recording that
collects pods, takes the weapons and gets further is stage 3's.
