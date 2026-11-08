# 1. Game design

What this covers:

- the game in a few lines (1.1);
- its screens: the menu, play, the end of a game, the end of a zone (1.2);
- the play screen and the HUD (1.3);
- the player: moves, shots, grenades, the exoskeleton (1.4);
- what kills him (1.5);
- 125 screens in five zones (1.6);
- the score, the lives, the bonuses and the Hall of Fame (1.7);
- 48K and 128K, the cheat, the difficulty (1.8);
- what no recording reached (1.9).

It describes the game as a player meets it. Every rule has its routine; the rules as code are in
[doc 10](10-gameplay-logic.md), the objects in [doc 7](07-objects.md). The names are those of `src/game/game.ann`
([Terms](README.md#terms)). The recordings it rests on:

- `c1`: power-on with `Exolon.tzx`, 48K, the load, then 16 000 frames of seeded random play (WALKTHROUGH 1). Opened
  read-only as `work/docs/docA/c1` on an own instance (port base 27000). Four games, all on screen 0.
- `h1`: a clone (`entry-score.z80`, the score set to 009000): GAME OVER, the name entry, the Hall of Fame.
- `w/NNN`: 97 warp clones (`entry-imm.z80` with the screen number set to NNN and the ZXDB POKEs for lives,
  ammunition, grenades, immunity, mines and traps), every screen 0-124 reached (WALKTHROUGH 6.0).
- `x2`: a clone with the same POKEs from screen 0: five screen changes in 3000 frames.

The clones are exploration only: each statement below also cites the code.

## 1.1 The game

- Exolon (Hewson Consultants, 1987, by Raffaele Cecco) is a flip-screen run-and-gun game.
- The player walks right through 125 screens, one at a time. The left edge is a wall: there is no way back
  (`TestLeft $8122` blocks X = 0).
- Each screen is a fixed scene of scenery and hazards. He shoots, throws grenades, jumps and ducks to get through.
- Every 25 screens a zone ends with a bonus. After screen 124 the game starts again at screen 0 with the score kept.
- Nine lives, 99 shots and 10 grenades at the start (Start `$6D60`, StartGame `$758A`).

## 1.2 The screens

![Exolon's screens: the menu, play, the end of a game, the end of a zone](img/design/modes.png)

How to read the figure:

- **Nine screens**, each the Spectrum screen at the end of the frame named under it, read with TTD `memory_at`.
- **1-4** come from `c1`, the original game: the menu (frame 12500), define keys (14900, with keys typed at random by
  the seeded play), play on the first screen (16250), GAME OVER over the last screen (18400).
- **5-6** come from `h1` (clone): the name entry (6600) and the Hall of Fame rolling up (6760).
- **7-9** come from `w/124` (warp clone on screen 124): the zone-end bonuses (640), CONGRATULATIONS after the last
  screen (900), the bonus screen (1000).
- **The point**: the game has one play screen and six full-screen panels; all of them are printed by the one string
  interpreter ([doc 6](06-rendering.md), 6.3).

```bash
python3 tools/fig_sheet.py --columns 3 --title "Exolon's screens: the menu, play, the end of a game, the end of a zone" \
    --subtitle 'c1 is the original game; h1 and w124 are clones with POKEs (a score of 9000; the warp to screen 124)' \
    --out docs/img/design/modes.png work/docs/docA/c1@12500='1. the menu (c1 frame 12500)' ...
```

(the full command, with the nine captions, is in `work/docs/docA-NOTES.md`.)

The panels and their routines:

| Screen | Routine | When |
| --- | --- | --- |
| the menu | MainMenu `$6DA1` | after the load, GAME OVER, the abort; keys 1-5 ([doc 5](05-controls.md)) |
| define keys | DefineKeys `$6FAB` | menu key 2 |
| GAME OVER | GameOver `$A02A` | the last life lost; a red band over the last screen |
| the name entry | HallOfFameInsert `$A073` | the score beats an entry of the Hall of Fame |
| the Hall of Fame | HallOfFameRoll `$7149`, ShowHallOfFameFirst `$7145` | after a name entry, or the menu left alone for 2500 passes |
| the zone-end bonuses | ZoneEnd `$A817` | the end marker of screens 24, 49, 74, 99, 124 |
| CONGRATULATIONS | RoundEnd `$A867` | after screen 124 |
| the bonus screen | BonusScreen `$A8DB` | after each zone end |

## 1.3 The play screen

The play screen is screen 3 of the figure above:

- **Rows 0-21**: the scene, printed once when the player enters ([doc 6](06-rendering.md), 6.4). The scene does not
  scroll.
- **Row 22**: the labels AMMO, GRENADES, POINTS, LIVES, ZONES, each in its colour (HudText `$76A2`).
- **Row 23**: the counters under them: ammunition 0-99 (`$8E5A`), grenades 0-10 (`$8E66`), the six-digit score
  (`$AD8A`), the lives 0-9 (`$8E7A`), and ZONES, which is the screen number 0-124 (`$8523`), not the zone.
- **The player** is a 24x32 sprite, 3 cells wide and 4 high. He is the only sprite of that size; every enemy is
  16x16 or smaller ([doc 6](06-rendering.md), 6.5).

## 1.4 The player

Moves (MovePlayer `$81A4`, once a pass; a pass is about 2 frames, [doc 4](04-game-loop.md)):

| Move | Control | Rule |
| --- | --- | --- |
| walk | left, right | 2 pixels a pass; a change of direction costs one pass |
| crouch | down, on the ground | no movement; his shots leave lower |
| jump | up, on the ground | 22 passes, up 18 pixels and down; the take-off direction keeps moving him; no steering |
| fall | nothing below | 4 pixels a pass, no steering |

Weapons and equipment:

- **Shots** (FireControl `$8338`): one shot a press, one round of ammunition each. A shot is a short line that flies
  10 pixels a pass for about 100 pixels. No shot when he stands at the right edge (X from `$76`).
- **Grenades** (ThrowGrenade `$9208`): fire held for 15 passes throws a grenade in an arc, when one is left and none
  is flying. A grenade breaks the destructible scenery pieces (DestructibleKinds `$94C6`: 10 kinds) and destroys a
  missile launcher.
- **Pods** (Pods `$9942`): walking into the ammunition pod gives 99 rounds, into the grenade pod 10 grenades.
- **Teleports** (Teleports `$98BA`): up in one booth moves him to the other pad of the screen.
- **The exoskeleton** (ExoSuitBooth `$9F2D`): up in an exoskeleton booth (screens 9, 34, 60, 90, 109) puts it on or
  takes it off. Worn, mines and traps cannot kill him (ShieldedKill `$9CAA`) and he fires a second shot 6 pixels lower.
  It costs the bravery bonus at the zone's end.

Witnesses: `c1` (walks, jumps, shots on screen 0; frames 17494-17542 one jump, `$82F7` from 21 down to 0 and Y from
`$70` to `$5E` and back), `x2` (fire held: grenades; five screens), the warp runs (booths, teleports, pods).

## 1.5 What kills him

| Hazard | Routine | How |
| --- | --- | --- |
| gun turrets | AnimateTurrets `$8F95`, MoveShells `$90A2` | fire shells to the left at random (6 times in 256 passes when idle) |
| gun emplacements | Guns `$9D7F`, MoveGunShots `$9DD6` | fire left when he is more than 60 pixels to their left; a gun's shot can be shot down (50 points) |
| mines | Mines `$9152` | an armed mine blows when he stands on it; it then burns |
| traps | Traps `$9C15` | a probe rises out of the floor and sinks again |
| balls | MoveBalls `$9A23` | eight from each spawner, wandering at random; 50 points each |
| aliens | AliensStep `$A360` | fly fixed paths; 150 points each |
| the homing missile | HomingMissileStep `$A26B` | from a launcher on the right, steering towards him |
| the force field | ForceFieldStep `$ABCF` | a column of colour-cycling cells that kills on contact |
| the idle missile | IdleMissileStart `$AC59` | sent after 700 passes (about 28 s) on one screen |

A death plays a leap and a fall, takes a life and restarts him where he entered the screen, with 99 rounds and 10
grenades. He cannot die again for the next 20 passes ([doc 4](04-game-loop.md), 4.6).

## 1.6 125 screens, five zones

![Five zones of 25 screens, each ending at a gate (24, 49, 74, 99, 124)](img/design/zones.png)

How to read the figure:

- **15 of the 125 screens**, each at frame 250 of the warp clone started on it (`w/NNN`). The caption gives the
  screen number and what is new there.
- **Rows** run through the five zones: each zone starts on screen 0, 25, 50, 75 or 100 and ends at a gate on screen
  24, 49, 74, 99 or 124.
- **The colours change by zone**: the ground is red and magenta in zones 1-3 and green from screen 75.
- **The point**: the screens are built from a set of 62 scenery elements ([doc 6](06-rendering.md), 6.4), so the
  zones look alike; the hazards make each screen.

```bash
python3 tools/fig_sheet.py --columns 5 --scale 0.66 \
    --title 'Five zones of 25 screens, each ending at a gate (24, 49, 74, 99, 124)' \
    --subtitle 'frame 250 of the warp runs w/NNN (clones: entry-imm.z80 with the screen number set to NNN, tools/warp_snapshot.py)' \
    --out docs/img/design/zones.png work/w/000/screens/000250.scr='0: the landing craft|(the start)' ...
```

(the full command is in `work/docs/docA-NOTES.md`.)

- The screen number (`$8523`) rises by one when he walks off the right edge (NextScreen `$8253`). He enters the new
  screen on the left at the height he left the last.
- After screen 124 the screen number becomes `$FF` and the next screen is 0 (RoundEnd `$A867`). The game has no end
  but this loop.
- No plain recording got past screen 0. `x2` (clone, the ZXDB POKEs) changed screen at frames 751, 1481, 1771,
  2421 and 2951. The warp runs reached every screen.

## 1.7 Score, lives, bonuses, the Hall of Fame

| Event | Points | Routine |
| --- | ---: | --- |
| a ball shot | 50 | ShotsHitBalls `$9B52` |
| a gun's shot shot down | 50 | ShellsVsShots `$9E37` |
| an alien shot | 150 | AliensVsShots `$A5CA` |
| a missile launcher destroyed while its missile flies | 850 | HomingMissileStep, AddBonusTicks `$9EAF` |
| a bonus pick-up | 1000 | PickupsVsPlayer `$A30B` |
| the zone's end: LIVES BONUS | 1000 a life | ZoneEnd `$A817` |
| the zone's end without the exoskeleton: BRAVERY BONUS | 10 000 | ZoneEnd |
| the bonus screen: the pointer stopped on an odd line | 1000, 3000, 5000 or 7000 | BonusScreen `$A8DB` |

- The bigger bonuses are paid 25 points a pass with a click (PayBonusTick, BonusTicks `$9ED6`), so the score runs up
  on the HUD.
- **Lives**: 9 at the start, one more at a zone's end when below nine (ZoneAddLife `$A8A1`), never more than 9.
- **The bonus screen** (screen 9 of the figure in 1.2): an arrow steps down eight lines, 00000 01000 00000 03000
  00000 05000 00000 07000; fire stops it. The pointer is never reset: it goes on from where it last stopped.
- **The Hall of Fame** (HallOfFame `$71F1`): 50 entries of a name and a six-digit score. The image's table starts with
  RAFFAELE, SURTANI, SCRAGGY, SABATTA!, PADDY, LOFTY, JIMBO, LEO, GLEN, MORANGE, all at 001000 (`x1`, `h1`). A score
  that beats an entry asks for an 8-letter name and then shows the table ([doc 5](05-controls.md), 5.5).

## 1.8 Machines, the cheat, the difficulty

- **48K and 128K run the same image.** The 128K differs only in sound: the AY plays the title music and the effects
  instead of the beeper ([doc 9](09-sound.md); the machine test in [doc 2](02-architecture.md), 2.1).
- **The ZORBA cheat**: define the keys as Z, O, R, B, A and the lives never run out (ZorbaCheat `$7046`); a jingle
  says it is on. The same again turns it off ([doc 5](05-controls.md), 5.4).
- **No difficulty setting**: the menu has none. The round end changes only the screen number, the ammunition, the
  grenades, the exoskeleton and one life (RoundEnd `$A867`, ZoneRefill `$A8A5`), so the second round's screens are
  the first round's. Whether any hazard reads a round count was not searched beyond those routines. The hazards'
  randomness comes from one generator, Random `$AD36`.
- **The speed** is not fixed: a pass takes about 2 frames when quiet and up to 4 when the player turns or a beeper
  effect plays ([doc 4](04-game-loop.md), 4.5). The game slows down when much happens.

## 1.9 What no recording reached

- A screen change in a plain recording: `c1`'s seeded play never left screen 0. Everything past screen 0 comes from
  clones (`x2`, the warp runs) and the code.
- ZoneAddLife `$A8A1` (an extra life at a zone's end): the warp runs had nine lives.
- The pause, the abort keys and the ZORBA cheat: only the annotation agents' clone runs ([doc 5](05-controls.md), 5.6).
- The menu's timeout to the Hall of Fame (HallOfFameRoll `$7149` from the menu): `c1` always pressed a key in time.
- Traps in a case recording: every warp run had the trap POKE; exC's clone runs `t1` / `t2` ran them.
