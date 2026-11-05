# Nether Earth GS (Tron Z, 2002; tape: Hood, 2017)

State: source, resources and documents complete (2026-11-05); the SCL, the TRD and the TAP rebuild byte for byte
from source.

| | |
| --- | --- |
| Machine | Pentagon 128 (or any 128K) with a General Sound card (GS 512 KB or NeoGS); the disk with TR-DOS |
| Authors | the game: Argus Press Software, 1987; the GS conversion: Tron Z, 2002 (the loading screen's "TRON 2002"); the tape: Hood, 2017 ("Conversion from TRD by Hood.7.4.2017") |
| The SCL | `orig/NE_GS_TZ.zip` (md5 b5da07ecbed48679c23473b2164bb828, SHA-1 9c4f84b75819b0a8f9b01432bb2849d8a2f8c4b2), holding `NE_GS_TZ.SCL` |
| The TRD | `orig/Nether Earth (1987)(Argus Press Software Ltd)(EN)(GS)[h 2002 Tron Z].trd` (md5 b6e5fe105f600ae3dd1221e16cc8062e, SHA-1 63a0fea73f0711f255e8337b1a78413e7e907dfc) |
| The TAP | `orig/Nether Earth (1987)(Argus Press Software Ltd)(EN)(GS)[h 2017 Hood, Tron Z].tap` (md5 0ef2b5a6c3047da6185c31fded334ff6, SHA-1 245bbe488c0a558ce04de0144d16fbb48e2005f9) |

[Nether Earth](../nether-earth/README.md) with General Sound: a ProTracker module for the menu and 14 sampled
effects in place of the beeper. The game is Nether Earth's image at Nether Earth's addresses. 159 bytes changed, all
of them sound: a bridge in NE's spare bytes pages a driver in at `$C000` and the beeper writes became `NOP`s. The
disk loader uploads the module and the effects without waiting for the card, so the card loses the module and five
effects: the disk plays no music, and most sounds come out as the wrong sample
([9.2](docs/09-sound.md#92-what-is-on-the-card)). Hood's 2017 tape loads them with waits and plays them all. It also
asks "music ON / OFF", and it hangs at the first sound unless it is started from 48 BASIC with paging free
(`USR 0`, [1.5](docs/01-game-design.md#15-the-hang-of-hoods-tape-on-a-128k)). The TRD adds a HRUM-packed boot menu and two
programs of other origins: `Neart481`, a cracked 128K build, and `Neart482`, a RAPEWARE intro with a game inside
([1.2](docs/01-game-design.md#12-starting-each-medium)).

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS]     # builds the SCL, the TRD and the TAP into build/ and compares each with orig/
```

One build at a time: it holds `build/.lock` (a folder) while it runs. The parts, each with its own script:

| Part | Source | Resources (`src/res/`, [README](src/res/README.md)) | Build |
| --- | --- | --- | --- |
| the game `neart001`, `$6590-$FFFF`, two targets | `src/game/*.asm`, 24 modules from `src/game/game.ann` (577 entries) | `game/`: font, 89 sprites, view edges, level, NE's silent menu tune, order names | `tools/build_game.sh` |
| the disk: BASIC, loader `neart022`, driver `neart021` (bank 1) | `src/disk/` | `music/` (the module), `sfx/` (14 WAV), `screen/` (`loading.png`), `text/` | `tools/build_loaders.sh` |
| the tape: Hood's BASIC, loader `neart0222`, driver (bank 6) | `src/tape/` | the same, `text/tape-basic.txt` | `tools/build_loaders.sh` |
| the TRD's `boot` (HRUM 3.5 + "Work Loader v1.2"), `Neart481`, `Neart482` | `src/trd/` | `trd/`, `text/trd-*.txt` | `tools/build_trd_extras.sh` |
| the media layouts | `src/media/{scl,trd,tap}.txt` | `media/` (the TRD's leftover bytes) | `tools/mkscl.py`, `mktrd.py`, `mktap.py` |

The game's source is written from its annotations:

```bash
python3 tools/game_mkgame.py --install        # src/game/*.asm and src/res/game from src/game/game.ann
python3 ../../kit/check_docs.py --case .
```
