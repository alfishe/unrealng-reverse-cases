# Deflektor (Gremlin Graphics, 1987)

State: docs written, in review (2026-11-13). 12 documents, 198 figures (PNG), 24 animations (GIF), 33 mermaid diagrams
and 20 audio files (1 MP3, 19 short WAV; 764 KB), counted on 2026-11-13 with:

```sh
ls docs/[0-9][0-9]-*.md | wc -l; find docs/img -name '*.png' | wc -l; find docs/img -name '*.gif' | wc -l
cat docs/[0-9][0-9]-*.md | grep -c '^```mermaid'
find docs/audio -name '*.mp3' | wc -l; find docs/audio -name '*.wav' | wc -l; du -sh docs/audio
```

| | |
| --- | --- |
| Machine | 48K (ZXDB 1327: ZX-Spectrum 48K) |
| Profile (AGENTS.md 4.0) | a puzzle game for one player against an energy bar ([doc 1](docs/01-game-design.md)): a cursor turns mirrors so the laser's beam burns every cell (`$40`) and then enters the open receiver; 60 levels of 15 x 9 cells, 135 bytes a slot from LevelData `$B000`, practice levels from slot 60 (`$3C`), an ending after level 60 (a plug and a kettle); mirrors, polarisers, absorbing and reflecting walls with quarter masks, prisms, fibre-optic pairs, mines ("MINE ALERT"), gremlins that turn mirrors ("BEWARE OF THE GREMLINS!"), an overload bar (the beam back into the laser, or 40 steps or bounces) and an energy bar ("ENERGY DRAINED"); three lives (`$837D`); a score and a hall of fame with a name entry ([doc 8](docs/08-hud-and-text.md)); MainLoop `$854A` and PassEnd `$85AE` never wait for the frame (4.85 frames a pass in the RZX run; [doc 4](docs/04-game-loop.md)); TraceBeam on a half-cell lattice, 16 directions ([doc 10](docs/10-gameplay-logic.md)); the play area drawn into buffers at `$E300-$FCFF` and copied to the screen by marks, timed against the raster ([doc 6](docs/06-rendering.md)); IM 2 (table `$FE00-$FF00` of `$FD`, `JP $A32A` at `$FDFD`); beeper only: TwoTone, PlaySweep, PlayNoise, flagged sounds in the interrupt and a three-voice title tune of 176 notes ([doc 9](docs/09-sound.md)); the menu's seven options (1 KEYBOARD, 2 SINCLAIR, 3 KEMPSTON, 4 PROTEK-AGF, 5 DEMO, 6 PRACTICE, 7 START GAME); Q A K L with fire on the bottom half-rows, P pauses ("INTERMISSION"), U + G aborts, a dormant level cheat ([doc 5](docs/05-controls.md)); a turbo tape with its own loader, a loading screen drawn by a script, a decryption chain and a mover ([doc 3](docs/03-build-and-load.md)) |
| Authors | Costa Panayi (code), Ben Daglish and John O'Brien ("Jobbee", music), from ZXDB 1327 and the title scroll ("DEFLEKTOR, WRITTEN BY COSTA PANAYI, WITH HELP FROM THE ALIEN, MUSIC BY BEN AND JOBBEE, (C)1987 VORTEX SOFTWARE", the scroll text at `$A203`); the loader is by D.G. Cooke 1987 (TOSEC names it "[Search Loader]") |
| Release | ZXDB 1327: Deflektor, Gremlin Graphics Software Ltd, 1987, £7.99; Erbe Software S.A. (Spain), 1987; in the compilations 10 Mega Games Volume One (Gremlin), Load 'n' Run issue 48 ("Specchi") and ZX-Spectrum Vega |
| Original | `orig/Deflektor.tzx.zip` (md5 `195f043d9de9aced556f4507723d1d86`, SHA-1 `cbdae96b31e681d0fcb0578c8aef68b06073cc92`; ZXDB `pub/sinclair/games/d/Deflektor.tzx.zip`, the share's copy unchanged): `Deflektor.tzx` (58 760 bytes, md5 `d3ddae68bfbc3c64bc3f142261573fc2`, SHA-1 `ee96f6142c0f05ed7a65bc2db02befd0357b727b`), three blocks: a Program header "DEFLEKTOR", its 384-byte BASIC with the loader, and one turbo block of 58 316 bytes in the loader's own byte code, no flag byte ([doc 3, 3.1 and 3.3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)) |

## Other releases and copies

Every copy the collection index lists was copied unchanged into `work/candidates/<source>/` by
`tools/fetch_copies.py` (`work/stage1/fetch-copies.txt`). `tools/media_compare.py` compared the tapes block by block
(`work/stage1/media-compare.txt`) and `tools/copy_compare.py` every copy by the share of the game it holds in 256-byte
pieces (`work/stage1/copy-compare.tsv`). The original's turbo block is in the loader's own code, so a copy is compared
with the game as it runs (`$6000-$DFFF` at the jump to `$8382`, `c1` frame 15752) and as the loader leaves it
(`$5C00-$9DEF` and `$C000-$FFFF` at `c1` frame 15635; still encrypted, found in no copy)
([WALKTHROUGH 0](WALKTHROUGH.md#0-the-medium)).

| Copy | What it is | How it differs from the original |
| --- | --- | --- |
| ZXDB `Deflektor(ErbeSoftwareS.A.).tzx.zip`: `Deflektor (Erbe).tzx` | the Spanish release | the header and BASIC byte for byte; the turbo block differs in 32 bytes from offset 306 |
| TOSEC 2020 `Deflektor (1987)(Gremlin Graphics).tzx`, `Deflektor (1987)(Gremlin)(48k)[tzx].tap` | another dump of the Gremlin tape | all blocks byte for byte but the turbo block's last byte (`$AA` against `$A0`, in the bits after the last used ones); its turbo block is written at standard timing, and it loads in unreal-ng |
| TOSEC 2020 `10 Mega Games Volume One - Deflektor + North Star + Masters of the Universe - The Movie (1988)(Gremlin Graphics).tzx` | the compilation tape, Deflektor first | Deflektor's three blocks byte for byte with the same timing; the turbo block ends with a 16 561 ms pause where the original's has none. The `c1` recording loads this copy ([WALKTHROUGH 0](WALKTHROUGH.md#0-the-medium)) |
| ZXDB `Deflektor.tap.zip`: `DEFLEKTO.TAP`; the ULA+ pack's `Deflektor.tap` | a re-save: a 168-byte BASIC, the loading screen DEFL.SCR (4539 bytes at 30000) and DEFL.CDE (23 266 bytes at `$6000`); the ULA+ copy adds a palette block first | packed: none of the 256-byte pieces of the game |
| Disk and Microdrive conversions and translations: ZXDB `Deflektor.dsk` (+3), the TOSEC 2020 and zxart TR-DOS copies (with the Russian translations), the TOSEC MDR copies | non-standard versions, recorded only (owner's rule: not studied) | `work/stage1/copy-compare.tsv` scores them; none is used |
| TOSEC 2020 tape hacks Bill Gilbert, San-San, Larin D.V, Andy Solovarov; zxart `(EN)[h].tap`, `[h Master Studio]` | re-saves with new loaders | 84 to 116 of the 128 pieces of `$6000-$DFFF` |
| zxart `(EN)[h Puntass].tap`; TOSEC 2012 `[h Jupiter 77][t].$b` | re-saves | packed: no piece |
| RZX archive `deflektor.rzx` (Roman Rugalenko, 48K, 346 004 frames, recorded with rollback) | someone else's run through all 60 levels to the ending | used, said so, to reach every level ([WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)) |
| ZXDB `Deflektor (1987)(Gremlin Graphics Software).pok` | Infinite Lives 34473,0 (`$86A9`); Infinite Time 42707,201 (`$A6D3`); Infinite Energy 42557,201 (`$A63D`); No Overload 42627,201 (`$A683`); Infinite lives 41784,0 (`$A338`) | a POKE file |
| ZXDB `Deflektor.ay.zip`, the local `Ben_Daglish_-_Deflektor_(1987).ay`; the ZXDB instructions, map, screens, the Erbe and multi-language inlays | the AY rip of the title tune; documents | not programs of the tape |

## Sources and credits

- The game: Deflektor, Gremlin Graphics Software Ltd, 1987 (ZXDB 1327); written by Costa Panayi "with help from the
  Alien", music by Ben Daglish and John O'Brien ("Ben and Jobbee"), as the title scroll (`$A203`, "(C)1987 VORTEX
  SOFTWARE") and ZXDB name them; the tape's loader by D.G. Cooke, 1987.
- The tape: ZXDB `pub/sinclair/games/d/Deflektor.tzx.zip`, the file in `orig/`.
- The RZX run: the RZX archive's `deflektor.rzx`, recorded by Roman Rugalenko with rollback, 48K, 346 004 frames:
  another player's game through all 60 levels and the ending, used, and said so, for the levels and the ending no
  keyed play of ours reached ([WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)).
- ZXDB 1327 (spectrumcomputing.co.uk): the releases, the instructions, the map, the POKE file.
- No SkoolKit disassembly of Deflektor was found on GitHub (one search, 2026-11-12; `work/stage1/NOTES.md`); every
  name is ours.

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS]     # builds build/Deflektor.tzx and compares it with the TZX in orig/Deflektor.tzx.zip
```

The game source is `src/game/*.asm`, written by `kit/mkgame.py` from `src/game/game.ann`; the resources are
`src/res/` (`src/res/README.md`).
