# ATV Simulator (Code Masters, 1987)

State: docs written, in review (2026-11-16): docs 01-10 by three writers, docs 11 and 12 generated, integrated; the
tape builds identical from the sources. 12 documents, 90 figures (PNG), 48 animations (GIF), 96 mermaid diagrams and
5 audio files (3 short WAV, the longest 3.4 s; 2 MP3 over 5 s: the title tune and the engine; 1.4 MB), 13 recordings
(WALKTHROUGH 6.0), counted on 2026-11-16 with:

```sh
ls docs/[0-9][0-9]-*.md | wc -l; find docs/img -name '*.png' | wc -l; find docs/img -name '*.gif' | wc -l
cat docs/[0-9][0-9]-*.md | grep -c '^```mermaid'
find docs -name '*.mp3' | wc -l; find docs -name '*.wav' | wc -l; du -sh docs/audio; ls -d work/stage1/rec/*/ | wc -l
```

| | |
| --- | --- |
| Machine | 48K (ZXDB machine type "ZX-Spectrum 48K"): one tape, one load, no level loads. The image as the loader leaves it has no AY port write (no `LD BC,$FFFD` or `$BFFD` outside the screen bytes) and no paging (`$7FFD`): beeper only, the same on a 128K |
| Profile (AGENTS.md 4.0) | see [Profile](#profile) below |
| Authors | ZXDB 9306: Tim Miller, James Wilson, David Whittaker (music), Nigel Fletcher (inlay and poster art). The game's own title screen (recording c1, frame 14 640): "GAME DESIGN AND CREATION TIM MILLER", "MUSIC BY DAVID WHITTAKER", "PUBLISHED BY CODE MASTERS LTD". The Oliver twins are not credited on this game, neither in ZXDB nor on its screens |
| Release | ZXDB 9306: ATV Simulator (alias All Terrain Vehicle Simulator), Code Masters Ltd, 1987, £1.99; ZXDB genre "Simulation", two players. Re-releases: EDOS, Serma Software (Spain, 1987, 550 ptas); in the compilations Quattro Power, Quattro Power Vol. 5, Quattro Racers, The CD Games Pack, Christmas Megapack, Mega-Hot and Poke City; on the covertape Load 'n' Run 46 as "Dune Buggy". ZXDB denies the distribution of the tape file (`/denied/entries/0009306/ATVSimulator.tzx.zip`, 25 525 bytes, md5 `8569b2a27f39c9ce029c0bfd37ccca4f`) |
| Original | `orig/ATVSimulator.tzx.zip` (25 601 bytes, md5 `3bf1d87bbaa288c2b81e2d9888a45770`, SHA-1 `f23c81b4d38b96c164482f586bd3d094d3e2d040`; the World of Spectrum file of ZXDB's release 0, from the collection's mirror; its zip is not ZXDB's (another size), the collection index names both as the same tape): `ATV Simulator.tzx` (47 124 bytes, md5 `ca7bb7957f69915fc965e81d49eb99a4`, SHA-1 `2846b7833e811716c5e12e4607391b4def90426e`; byte for byte TOSEC 2023-09 "ATV Simulator (1987)(Code Masters)[a].tzx" and zxart's "[p 1987 Code Masters Ltd].tzx"): eight standard-speed ROM blocks, a BASIC loader, a 34-byte machine-code loader and two headerless loads ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)) |
| Recorded from | the original TZX at ROM speed (recording c1). The case's unreal-ng binary (`e3d341d38`) lacks commit f13cee7da (an ended tape holds its last edge); this tape loads all the same: the game takes over at frame 14 114, the tape stops at 14 182 |

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Profile

What the documents found; each row links the document that shows it.

| Row (AGENTS.md 4.0) | ATV Simulator |
| --- | --- |
| Genre | a side-view off-road race against the clock on an all-terrain quad bike: six trails one after the other; one or two players; two ride the same trail at once on a split screen, player 1 above, player 2 below (the menu's ONE PLAYER / TWO PLAYERS; recording kb) ([WALKTHROUGH 6](WALKTHROUGH.md#6-the-game)) |
| The courses and the track | six trails: 1 SAND DUNING, 2 GRASSTRAKIN, 3 ICEBERGS, 4 PYRAMIDS, 5 TROPICANA, 6 SWAMP; each a course record (trails 1-4 at `$7C9C` + 6 n, trail 5 at `$EE84`, trail 6 at `$60AC`) with a length of `$690`, `$568`, `$5D4`, `$685`, `$6B5` and `$69B` distance units, and two lists: the objects and a second list along the distance ([doc 1, 1.5](docs/01-game-design.md#15-the-six-trails)) |
| The vehicle and its handling | the rider walks to the ATV and jumps on with fire; right accelerates, left slows, up and down the front wheel, fire jumps; Speed `$D77B` 0-21, the throttle +1 a pass, the brake and a landing -2; the nose up (wheelie) and down by AtvFrame; a jump powered by the take-off pass's rise; three crash tests (a step of 7 beyond the last rise, the nose test with its unsigned wrap, a sharp lift in the air) and the crash by speed (stop, stop and throw, a 24-pass tumble); full nose-up with Up throws the rider off the back; he walks back and gets on only falling onto the seat; fuel `$2000` a trail, 4 a pixel ([doc 10](docs/10-gameplay-logic.md), [doc 5](docs/05-controls.md)) |
| Rivals and obstacles | no computer rival; in a two-player game the other player on the other half of the screen; obstacles per trail (trail 1: tyre walls and humps; c1's bot crashes at distance 381, frame 15 580, and stays at 373), no obstacle type: the ground is read from the buffer's pixels under the wheels, so whatever list A draws is ground ([doc 7](docs/07-objects.md), [doc 10, 10.6](docs/10-gameplay-logic.md#106-the-crash)) |
| Timer and score | a clock in tenths, one tenth a game pass (7 frames), against a maximum per trail (60, 60, 60, 40, 50, 50; 30 once the six trails come round again); TIME OUT ends the game; a trail's finish shows EXTENDED PLAY and the LAP TIME; a score per player and a high-score table of five (HOT 20000 down to BUDDY 03000) with a name entry on a letter grid; the bonus ((max - lap) / 2 + 1) x trail + 1 keeps only its low byte before the multiply; a point shows as 10 ([doc 1, 1.6](docs/01-game-design.md#16-the-rules-the-clock-the-score-the-finish-and-the-bonus), [doc 8](docs/08-hud-and-text.md)) |
| Rendering | each player's window drawn into a 22 x 80 buffer (`$F03C`, `$F71C`) from two lists (the ground at the speed, the scenery at a quarter), sprites with 4-byte headers shifted in place by RotateSpriteLeft / Right (the costliest work of a pass), DeferredB behind and DeferredA in front of the ATV, then copied to the screen (CopyLines, racing the beam); the HUD drawn on the screen field by field ([doc 6](docs/06-rendering.md), [doc 8](docs/08-hud-and-text.md)) |
| Engine | IM 2 (`I` = `$FE`, vector `$8080` to the handler `$D9D2`; the title tune's own vector `$FDFD` to `$F961`); a game pass of 7 frames (a wait on the frame counter `$D6BC`) while the work fits: one player always (the heaviest pass in `c1` 91.3 %), two players often not (8-13 frames) ([doc 4](docs/04-game-loop.md)) |
| Sound | the beeper only: the engine from the interrupt every frame, the landing thump, the bonus count, and David Whittaker's two tunes (title and finish) on a two-channel player with its own IM 2 table; no sound for a crash, a throw or an empty tank ([doc 9](docs/09-sound.md)) |
| Controls | per player: player 1 KEYBOARD or KEMPSTON (the default), player 2 KEYBOARD or SINCLAIR; each keyboard redefinable on its table (player 1 S D F C Z, player 2 H J K M B: left, right, wheel up, wheel down, jump); keys read by ScanKeys in the interrupt and latched (the last 3 scans of a pass count); the one-player SINCLAIR line does nothing; AbortKey (key 1) is unreachable ([doc 5](docs/05-controls.md)) |

## Sources and credits

- The game: ATV Simulator, Code Masters 1987 (ZXDB 9306); by Tim Miller and James Wilson, music David Whittaker,
  cover art Nigel Fletcher (ZXDB); the title screen says "GAME DESIGN AND CREATION TIM MILLER", "MUSIC BY DAVID
  WHITTAKER", "PUBLISHED BY CODE MASTERS LTD" (recording `c1`, frame 14 640).
- The tape: the World of Spectrum file of ZXDB's release 0 (`orig/ATVSimulator.tzx.zip`); the TZX has no text or
  archive-info block and names no dumper.
- The POKEs, the instructions and the trail maps (Ladderman 2005): ZXDB, kept in `work/candidates/`.

## Other releases and copies

Each copy found is kept unchanged in `work/candidates/<source>/` (git-ignored). The blocks were compared byte for
byte with `tools/media_compare.py` against the original.

| Copy | Source | What differs |
| --- | --- | --- |
| `ATV Simulator (1987)(Code Masters).tzx` (md5 `8ff1487b…`) | TOSEC 2023-09 | the same BASIC, loader, screen and code; no headers before the screen and the code (the loader never reads them), other pauses |
| `ATV Simulator (1987)(Code Masters)[a2].tzx` and the `.tap` | TOSEC 2023-09 | the BASIC header says LINE 0 (one byte); the same data; no headers before the screen and the code |
| `[h Raf].tap` | TOSEC 2023-09 | a 2 148-byte BASIC ("RAF'90") in place of the loader; the same screen and code |
| `(EN)[p].tap` | zxart | a 103-byte BASIC, a 4 039-byte block `ATV.$` at 40000 and the code with 6 bytes changed (`$6338`, the text at `$696B-$696E`, `$DFE6` = `$C9`, `$EB5A` = `$00`: the ZXDB POKEs patched in) |
| eight `[h ...].scl` | TOSEC 2023-09 | TR-DOS conversions (Cleopatra '91, Vitaly System, Immortal Boneman '95, Integral '97, VAD '98, AmoNik / Welcome '00, Glen, Phantom, Tagilsoft '94, Popushin): not used |
| four `.z80` (one "(128K)"), the owner's `ATV_Simulator_1988_Codemasters.dsk` | TOSEC, the owner's archive | snapshots and a +3 disk: not used |
| `ATVSimulator.pok`, `ATVSimulator.txt`, three maps (`ATVSimulator.jpg`, `_2.png`, `_3.jpg`, Ladderman 2005) | ZXDB | the POKEs, the instructions (the inlay text of the C64 version), the trail maps |
| `David Whittaker - ATV Simulator (1987).ay` | the collection's AY rips | the title tune as an AY file |
