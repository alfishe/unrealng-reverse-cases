# Nether Earth GS: the documents

The game is [Nether Earth](../../nether-earth/README.md) (NE) at NE's addresses with its sound moved to the General
Sound card. These documents describe what is this conversion's own; for everything else they link NE's.

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the difference in one paragraph, how each medium starts (the TRD's boot menu, `Neart481`, `Neart482`), the tape's start and loading screen, what stays NE's (measured, side by side), the hang of Hood's tape on a 128K |
| [2. Architecture](02-architecture.md) | the machine budget, the memory map in play, the GS card's memory, the stages, what is NE's |
| [3. Build and load](03-build-and-load.md) | the three media, the disk load and its GS upload (with its bugs), the tape load, the TRD's other files, the variants |
| [5. Controls](05-controls.md) | starting each medium, the boot menu, the tape's music question; the game's keys are NE's |
| [6. Rendering](06-rendering.md) | the game's screens are NE's, the loading screen `neart000`, the progress bar over "GS-512", the frozen frame |
| [8. HUD and text](08-hud-and-text.md) | the game's texts (NE's), every text on the media with links to the readable copies |
| [9. Sound](09-sound.md) | what is on the card (the module, the 14 effects, what the disk loader really leaves), the GS commands, the driver and its ids, every call of the sound, the machine it needs, Hood's tape |

The game's source: [`src/game/`](../src/game/game.ann) (24 modules from `game.ann`); the resources:
[`src/res/README.md`](../src/res/README.md). How it was done: [WALKTHROUGH.md](../WALKTHROUGH.md).

## Texts

The texts of the media as readable Markdown, with English where needed ([8.2](08-hud-and-text.md#82-the-texts-on-the-media)):

| File | What |
| --- | --- |
| [disk-basic](texts/disk-basic.md) | the disk's BASIC `neart GS` |
| [tape-basic](texts/tape-basic.md) | Hood's tape BASIC `NetherE GS`: credit, music ON / OFF |
| [trd-boot-menu](texts/trd-boot-menu.md) | the TRD boot menu "Work Loader v1.2" |
| [trd-boot-hrum-credit](texts/trd-boot-hrum-credit.md) | HRUM 3.5's credit in `boot` |
| [trd-neart482-scroller](texts/trd-neart482-scroller.md) | `Neart482`'s intro scroller (Russian, with English) |
| [trd-neart482-sector-note](texts/trd-neart482-sector-note.md) | the note in `Neart482`'s BASIC sector |
| [trd-neart482-hacked](texts/trd-neart482-hacked.md) | the unread "HACKED BY" line of `Neart482` |
| [media-trd-sector9](texts/media-trd-sector9.md) | ZX Spectrum Navigator's credits in the TRD's sector 9, the disk label |
| [media-trd-leftovers](texts/media-trd-leftovers.md) | the words in the TRD's sector tails and free sectors |

## Recordings and runs

| Name | What |
| --- | --- |
| `x1`-`x8` | stage 1's live runs on Pentagon 128 (`work/stage1/xN`, [WALKTHROUGH 2](../WALKTHROUGH.md#2-stage-1-live-runs)): the SCL on NeoGS and GS 512 KB, the tape through the Tape Loader, 48 BASIC and `USR 0`, the TRD |
| `r1` | the L1 recording of the game from the SCL's main menu (`work/stage2/r1`): 12073 frames, 5 robots built; the source's code split rests on it |
| `rA` | the TRD extras' L1 recording (`work/stage2/trd/rA`) |
| `shots` | `tools/fig_capture.py`: the figures' frames, a Pentagon 128 + GS 512 KB and a 48K with NE's tape (`work/stage2/shots`) |

## Terms

- **GS**: General Sound, the Z80 sound card with its own 512 KB RAM, ProTracker module player and sample effects;
  the host talks to it through a command port (`$BB`) and a data port (`$B3`). NeoGS is the newer compatible card.
- **The driver** (`neart021`): the conversion's 248-byte routine (271 on the tape) that turns the game's sound id
  into GS commands; it lives at `$C000` of a RAM page of its own (`DriverBank`: 1 on the disk, 6 on the tape).
- **Sound id**: the value the game passes in A to `GsSound` (`$A583`); for the menus it is NE's old beep
  half-period ([9.4](09-sound.md)).
- **Effect N**: the GS's N-th loaded sample, as the driver numbers it.
- **The two targets**: one game source assembled plain (the disk's `neart001`) and with `-DHOOD_TAPE` (the tape's;
  4 bytes differ).
- **NE**, **ANE**: the cases [Nether Earth](../../nether-earth/README.md) and
  [Advanced Nether Earth](../../advanced-nether-earth/README.md).
