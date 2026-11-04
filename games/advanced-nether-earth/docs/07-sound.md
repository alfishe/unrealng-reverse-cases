# 07. Sound: two AY players, five tunes

NE has no AY music: a beeper title tune and beeper effects. ANE adds AY music everywhere but in NE's effects,
which stay as they are (the beeper). Two players are on the disk, each compiled with its tunes; the tunes were
found in the zxart.ee collection (`/Volumes/TB4-4Tb/Data/zx-spectrum/music`) by the name field inside the module
and compared byte for byte (the commands: `work/stage2/NOTES.md`).

## 1. The players

| Player (its own string) | Module format | Entry points | Where |
| --- | --- | --- | --- |
| "New SoundTrack Player By PHANTOM FAMILY'1996" | ProTracker 2 (the header: delay, positions, loop, 32 sample and 16 ornament pointers, the pattern pointer, the name "dd.mm.yy/hh:mm/...") | `$C000` init (its first instruction `LD HL,module`), `$C005` one frame | the intro, the game's music bank 1, Dead End's bank 3 |
| "PT 3 Player v1.0 by Nick of GDC" | ProTracker 3 ("ProTracker 3.1 compilation of ...") | `$C000` init, `$C005` one frame (the same layout: `LD HL,module`, `JR`, `JP play`) | the boot music in bank 1, Final Cut |

The module's pointers are absolute in the ProTracker 2 tunes (the zxart files hold offsets: ANE's copies have the
module's address added), so a tune is tied to its address. The PT3 player's string names version 1.0; its
comparison with the Pro Tracker 3.x player sources (Vortex Tracker's) is not done (section 4).

## 2. The tunes

| Tune | Where it plays | Module | zxart.ee file | Equal |
| --- | --- | --- | --- | --- |
| "MAD NIGHT BY SYRUS/EI/15.02.98" | the intro | PT2 at `$8772` | 79143 `Sairoos_-_MadNight_(1998).pt2` | 6939 of 7228 bytes at equal offsets, 288 differ (not followed) |
| "08.12.96/02:25/*X-MAN-MUSIC*" | the boot menu and the help | PT3 at `$CE21` (bank 1) | not found by its name | |
| "05.03.97/23:41/*X-MAN-MUSIC*" | play and the game menu | PT2 at `$CA45` (bank 1) | 83098 `X-Man_-_TAIGA_(1997).pt2` | 3243 of 3866 equal, 108 pointers relocated, 406 bytes differ (not followed) |
| "NETHER EARTH (END) by SYRUS/EI" | Dead End | PT2 at `$CA45` (bank 3) | 79174 `Sairoos_-_Nether_Earth_End.pt2` | all 2218: 2050 equal, 84 pointers relocated |
| "17.10.96/20:37/*X-MAN-MUSIC*" | Final Cut | PT3 at `$9A16` | not found by its name | |

The credits agree: "MUZAK...SYRUS" for the intro (the scroller), "X-Man: music" for the help ([12](12-claims.md)).

## 3. How the game plays it

Bank 1 holds the game's player and tune; every frame one handler pages bank 1, calls `$C005` and pages back the
bank the game had (`GameBank` `$67D9`): `MusicInterrupt` (`$6780`) outside play, `PlayMusic` (`$67B1`, after
NE's `ShowRadar`) in play ([04](04-game-loop.md)). `GameEntry` (`$A5DA`) calls bank 1's `$D8E1` once, and every
restart (`Restart` `$A5EF`) the player's init `$C000`. The two ends silence the AY themselves (`Silence` `$AE94`:
registers 0-14 zero) before Dead End or Final Cut start their own player. The boot's loader plays the intro's tune
the same way from an IM 2 handler (`LoaderInterrupt` `$6161`, `src/loader.asm`), from bank 6.

## 4. Open

- The PT3 player against the Pro Tracker 3.x players (which source, which version): not compared.
- The two PT3 tunes: not found in the collection by their names.
- The differing bytes of MAD NIGHT and TAIGA against the zxart files.
