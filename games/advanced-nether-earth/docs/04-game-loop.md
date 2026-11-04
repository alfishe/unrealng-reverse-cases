# 04. The game loop and the interrupts, with the music

The game loop is NE's (`PlayLoop`, NE's [04](../../nether-earth/docs/04-game-loop.md)); ANE changes how it is
entered, the interrupt plumbing (so that `$C000` can be paged) and its ends. Every name below is in
`src/game/ane-patches.asm` (ANE's) or NE's `game.ann` (NE's).

## 1. Entry and restart

| Address | Name | What |
| --- | --- | --- |
| `$A5DA` | `GameEntry` | the game block's end jumps here (SP `$6731`): bank 1's tune set-up (`$D8E1`), then `Restart` |
| `$A5EF` | `Restart` | every restart (NE's `JP Start`: abort key I, a load error, the end of a game): `DI`, SP 0, bank 1's player init (`$C000`), bank 0 back; then NE's `Start` from `Start + 4` (NE's first 4 bytes are overwritten) |
| `$A600` | `Start` (NE) | the IM 2 table, now at `$6800` of `$69` bytes, `JP` at `$6969`, `I = $68`; the handler `MusicInterrupt` |

## 2. The interrupts

NE's IM 2 table (`$FE00-$FF00`, vector `$FDFD`) lies in `$C000-$FFFF`, which ANE pages; ANE moves it to
`$6800-$6900` (NE's font place, bank 5) with the vector `$6969`: `ImJump` (`JP`, written by `Start`) and
`ImHandler` (`$696A`, NE's `Handler`). Every NE write of `Handler` (`$FDFE`) now writes `ImHandler`.

| Handler | Installed by | Work a frame |
| --- | --- | --- |
| `MusicInterrupt` `$6780` (NE: `StartInterrupt`, nothing) | `Start`, `ConstructionMenu`, `SaveGame`, (`GameStop`) | the tune: bank 1, `$C005`, the game's bank back (`GameBank` `$67D9`) |
| `PlayInterrupt` `$D566` (NE's) | `EnterPlay`, `StartRobot` | NE's frame work; its `CALL ShowRadar` is a `JP PlayMusic` (`$67B1`): the radar, the tune, back to `PlayInterrupt + $1F` |

`GameStop` writes `LD ($6D6A),HL` where `ImHandler` (`$696A`) is meant: a typo that would leave the play
handler in place and write two bytes into the view buffer. Nothing calls `GameStop` in ANE (both ends of
`CheckGameEnd` leave the game), so it never runs.

## 3. The ends of play

| Event | NE | ANE |
| --- | --- | --- |
| no warbase left for us | `GameStop`, "YOU HAVE NO BASES LEFT", a key, `Start` | `Silence`, IM 1, bank 3, `JP $D2EF`: Dead End |
| no enemy warbase (`GameWon` `$AEB1`) | `GameStop`, "YOU HAVE WON !", a key, `Start` | `Silence`, IM 1, bank 6's Final Cut block copied to `$6060` and run |
| key 5 (save) | `SaveGame`: tape | `JP SaveGameBlocks + 3`, then `GameSave` (`$6905`): bank 4's disk module, back through `SaveReturn` (IM 2, `JP` to `EnterPlay`) |
| key 5 in the main menu (load) | `LoadGame`: tape | `GameLoad` (`$A56A`): the disk module, back through `LoadReturn` (`$5B00` = `$FFFF`, `JP NewGameSetup`) |

The disk module's own work (the file name prompt, TR-DOS through ROM gadgets) is in bank 4 ([03](03-build-and-load.md) 4.3).

## 4. Not yet witnessed

The static run (`tools/ane_sim.py`) reaches `GameEntry` and NE's main menu; Dead End, the disk save and load and
the help pages were not recorded in stage 2 (no emulator run): the paths above are from the code.
