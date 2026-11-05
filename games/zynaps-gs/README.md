# Zynaps GS (ZX-Masters, 1997)

State: documents stage (2026-11-05). The disk is rebuilt from the case's own sources, byte for byte: the BASIC, the
boot, the loader, the options menu, the GS driver, the installer and the game (50 modules, 546 entries, every routine
named), packed by the case's Trush packer. The media are cut, the 13 modules and 22 FX rendered. Every sound site is
witnessed in play. The documents 1-13 are written, 13 being the differences from the 48K game
([docs/13](docs/13-differences-from-zynaps.md)); how they were made: [WALKTHROUGH](WALKTHROUGH.md) 6.

| | |
| --- | --- |
| Machine | a 128K Spectrum with TR-DOS and a General Sound card (128 KB is enough: the firmware uses 112 KB of it and the largest level fits, [9.8](docs/09-sound.md#98-128-kb-and-512-kb-the-cards-pages)) |
| Authors | the game: Dominic Robinson, graphics Steve Crow (Hewson, 1987); the GS conversion: Mike Blum, ZX-Masters, 1997; music and FX mixed by John Underwood and Dangerous; the modules credit wendetta 2175 / wortex design, kbx128 / tesko!, dextrous, pyratronik, nuke of lemon |
| Original | `orig/ZYNAP_GS.ZIP` (md5 `187e99851aad93ecd03c032e65f753aa`, SHA-1 `73c7880e5a262cfb9fd0883bfb00ebed07fc568e`), holding `ZYNAP_GS.TRD` (md5 `133a8fe861f814b2d6d67e6539c81b85`, SHA-1 `bc0661fc8f384d76b4d5c321c151d156b538c52e`) |

This is Hewson's Zynaps with General Sound. The disk holds 38 blocks packed by Alexander Trush's compressor. The
last of them carries Zynaps at its own addresses and an installer that patches 31 places in it.

- **Sound sites.** Each sound site calls a driver in bank 1, which plays sampled effects through the GS ROM's
  firmware. The beeper requests are gone, and the beeper player still runs but stays silent.
- **Music.** Each level has its own Protracker module (13 with the title). In "music & effects" mode, the module and
  10 effects are uploaded at each level change. In "only effects" mode there is no music and 21 effects.
- **The upload.** It waits for the card on every byte, so nothing is lost, unlike Nether Earth GS's 2002 loader.
- **128 KB cards.** The firmware keeps 112 KB for data and stops storing at its end; every level's module and FX
  fit, so nothing is overwritten ([9.8](docs/09-sound.md#98-128-kb-and-512-kb-the-cards-pages)).
- **The options menu.** Seven options and two more hidden behind key 0: INFINITE LIFE and SELECT LEVEL. INFINITE
  ROUNDS is on at the boot, so a game never ends ([5](docs/05-controls.md),
  [10.6](docs/10-gameplay-logic.md#106-the-hidden-options)).

The documents: [docs/README.md](docs/README.md); what the conversion changed against the 48K tape:
[13. Differences from Zynaps (48K)](docs/13-differences-from-zynaps.md). How the reverse was done:
[WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
sh tools/build.sh     # the TRD from the sources: build/ZYNAP_GS.TRD, compared with orig/ZYNAP_GS.ZIP's
sh tools/regen.sh     # the .asm again from the annotations (src/game/game.ann, src/disk/*.ann), then build.sh
```

`build.sh` needs sjasmplus (its path as the first argument or `SJASMPLUS`) and Python 3 with Pillow; one build runs at
a time (`build/.lock`). The sources: `src/game/game.ann` (the game, mkgame writes `src/game/*.asm`),
`src/disk/*.ann` and `src/disk/*.asm` (the disk parts), `src/res` (the resources and media, each with its README),
`src/media/trd.txt` (the disk's layout). `regen.sh` also needs the work files of stages 1 and 2 (the original's
bytes and the recordings), which are not in the repository.

Other tools:

```bash
python3 tools/fig_compare.py                                                     # docs/img/compare from work/stage2/shots
python3 tools/trush.py --scan work/tmp/blob.bin --out-dir work/media/unpacked     # the 38 Trush blocks
python3 tools/gs_media.py work/tmp/blob.bin work/media/unpacked work/media/gs     # 22 FX and 13 modules
python3 tools/gs_digest.py PORTS.jsonl                                           # a GS port history as commands
```
