# Deflektor (Gremlin Graphics, 1987)

State: in progress (stage 1).

| | |
| --- | --- |
| Machine | 48K (ZXDB 1327: ZX-Spectrum 48K) |
| Profile (AGENTS.md 4.0) | a puzzle game for one player against an energy bar ([WALKTHROUGH 6](WALKTHROUGH.md#6-the-game)): a cursor turns mirrors so the laser (cell code `$86`) burns every cell (`$40`) and then reaches the receiver; 60 levels of 15 x 9 cells of 16 x 16 pixels, 135 bytes each from `$B000` (`$B000 + $87 x level`, level variable `$81FF`), a practice level (slot `$3C`), an ending after level 60; walls with quarter masks, mines ("MINE ALERT"), gremlins ("BEWARE OF THE GREMLINS!"), an overload bar and an energy bar ("ENERGY DRAINED"); three lives (`$837D`); a score and a hall of fame with a name entry; the main loop around `$843C`; IM 2 (table `$FE00-$FF00` filled with `$FD`, `JP $A32A` at `$FDFD`); beeper sound and the title tune; the menu's seven options (1 KEYBOARD, 2 SINCLAIR, 3 KEMPSTON, 4 PROTEK-AGF, 5 DEMO, 6 PRACTICE, 7 START GAME); keyboard Q A K L with fire on the bottom half-rows, P pauses ("INTERMISSION"), U + G aborts; a turbo tape with its own loader, a decrypting stage and a mover |
| Authors | Costa Panayi (code), Ben Daglish and John O'Brien ("Jobbee", music), from ZXDB 1327 and the title scroll ("DEFLEKTOR, WRITTEN BY COSTA PANAYI, WITH HELP FROM THE ALIEN, MUSIC BY BEN AND JOBBEE, (C)1987 VORTEX SOFTWARE", the scroll text at `$A203`); the loader is by D.G. Cooke 1987 (TOSEC names it "[Search Loader]") |
| Release | ZXDB 1327: Deflektor, Gremlin Graphics Software Ltd, 1987, £7.99; Erbe Software S.A. (Spain), 1987; in the compilations 10 Mega Games Volume One (Gremlin), Load 'n' Run issue 48 ("Specchi") and ZX-Spectrum Vega |
| Original | `orig/Deflektor.tzx.zip` (md5 `195f043d9de9aced556f4507723d1d86`, SHA-1 `cbdae96b31e681d0fcb0578c8aef68b06073cc92`; ZXDB `pub/sinclair/games/d/Deflektor.tzx.zip`, the share's copy unchanged): `Deflektor.tzx` (58 760 bytes, md5 `d3ddae68bfbc3c64bc3f142261573fc2`, SHA-1 `ee96f6142c0f05ed7a65bc2db02befd0357b727b`), three blocks: a Program header "DEFLEKTOR", its 384-byte BASIC with the loader, and one turbo block of 58 316 bytes (flag `$19`) in the loader's own pulse code ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)) |

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

## Sources

- ZXDB 1327 (spectrumcomputing.co.uk): the releases, the authors, the instructions, the map.
- No SkoolKit disassembly of Deflektor was found on GitHub (one search, 2026-11-12; `work/stage1/NOTES.md`).

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS]     # builds build/Deflektor.tzx and compares it with the TZX in orig/Deflektor.tzx.zip
```

The game source is `src/game/*.asm`, written by `kit/mkgame.py` from `src/game/game.ann`; the resources are
`src/res/` (`src/res/README.md`).
