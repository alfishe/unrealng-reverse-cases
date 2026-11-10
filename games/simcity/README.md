# SimCity (Infogrames, 1990)

State: docs written, in review (2026-11-10). The tape's seven data blocks rebuilt byte for byte from the annotated
source (29 modules) and the 54 editable resources in `src/res`, protection included; docs 01-12 (12 documents, 120
figures, 24 animations, 5 WAVs, 77 mermaid diagrams), counted with
`ls docs/[0-9][0-9]-*.md | wc -l; for e in png gif wav; do find docs -name "*.$e" | wc -l; done; grep -h '^```mermaid' docs/*.md | wc -l`.

| | |
| --- | --- |
| Machine | 48K (the +3 disk release pages memory in its boot code; the tape image has no paging, beeper only) |
| Profile (AGENTS.md 4.0) | simulation, city building: a 96 x 96 map of one byte a cell at `$C450-$E84F` (address `$C450 + 96 y + x`, MapAddr `$6BE6`), seen through a 32 x 16 cell window under a menu bar, an icon bar of 14 tools and a status box ([WALKTHROUGH 6.2](WALKTHROUGH.md#62-the-city-map-and-the-state)); rendering in character cells: a map byte below `$80` is one of 94 tiles at `$EA68 + 8 x cell` (attribute `$F530 + cell`), bytes from `$80` are rows of buildings drawn from 244 tiles at `$ED58` ([doc 2, 2.9](docs/02-architecture.md#29-the-map-tiles-and-a-whole-city)), zones 3 x 3 cells, one view row redrawn a UI pass ([doc 6](docs/06-rendering.md)); two tasks on two stacks, switched by the IM 2 handler `$F70B` (I = `$FD`, a 257-byte table of `$FC` at `$FD00-$FE00`, `JP $F70B` at `$FCFC`) every frame unless SwitchOff `$F705` is set ([doc 4](docs/04-game-loop.md)): the UI task, UiLoop `$8FCC-$901B` (no HALT), whose busy wait UiDelay `$8FD5` (2000 loops, 74 % of a frame) takes about a third of all the CPU time and is where the switch hands the frames over, and the simulation task SimTask `$835F`, which gets about one frame in three in play (32-34 %), almost none in the menus (SwitchOff held: the simulation is frozen), and runs a pass over the whole map in 72-157 of its own frames (242-471 wall frames in play), a month every 1, 2 or 4 passes by the speed ([doc 4, 4.8](docs/04-game-loop.md#48-the-passes-per-frame-of-each-task)); the rules ([doc 10](docs/10-gameplay-logic.md)): a zone grows toward half its score (land value - pollution - crime - tax penalty + demand), and the growth ceiling is set by the tax: 8 x the tax rate off every score (10 x on medium, 9 x on difficult), so the bot cities at 7 % stop near 6000 and 9300 people, while the same city at 0 % passed 10 000 people (CITY) at the 1936 year end, about two game years in ([doc 10, 10.10](docs/10-gameplay-logic.md#1010-the-category-and-the-growth-ceiling)); a bug in ApplyFunding `$952A`: its fire branch tests TransportCost against 20, not FireCost, so with a road network costing less than 20 the fire stations are at full strength whatever their funding ([doc 10, 10.8](docs/10-gameplay-logic.md#108-funding-the-budget-and-taxes)); the state: 24-bit funds at `$8F97`, the month at `$8F9B` and the year at `$8F9C` (from JAN 1902), the population at `$8443` (24 bits), the R, C and I zone counts at `$8446`, `$8448`, `$844A`, the advice line chosen from their ratios (`$99AD`); no scenarios (every city comes from a five-digit gene), no bankruptcy or game over (no text for it, and Spend `$6E46` never lets the funds go below 0); six disasters from a menu, but at random only the tornado (RandomDisaster's gate fixes the next draw: about 1 in 65 536 a try, [doc 1, 1.10](docs/01-game-design.md#110-the-disasters)); beeper sound only: a noise for the disasters and a refusal tone (`$5B48`, `$5B66`), and with SOUND off the noise leaves the interrupts off, a bug of the original ([doc 9, 9.6](docs/09-sound.md#96-sound-off-the-interrupts-never-come-back)); the +3 disk release is the same program reassembled for disk: its own boot sector reads it by raw sectors, no protection, six bytes inserted in Entry and the code from Entry's `$5B27` on 6 bytes higher, disk menus in place of the tape's ([doc 2, 2.8](docs/02-architecture.md#28-the-3-disk-release)) |
| Authors | Probe Software Ltd for Infogrames: Antony R. Lill (Spectrum programming), Simon Butler (graphics) (ZXDB 4509); the about box says "SPECTRUM PROGRAMMING A.R.Lill", "SPECTRUM GRAPHICS A.Lill & J.L", "FOR PROBE SOFTARE LIMITED" (sic), "CONCEPT & DESIGN W.Wright", "(C) 1989 MAXIS SOFTWARE" (text at `$A0CC`); the loading screen is signed "SIMON" |
| Release | ZXDB 4509: Infogrames, 1990, a licence of Maxis' SimCity (Will Wright); tape (this release) and +3 disk; the Spanish re-release by Erbe Software (1990). Not the same game: ZXDB 31079 "Sim City - The Text Adventure" |
| Original | `orig/SimCity.tzx.zip` (md5 `3eb4d4d9c9f1d904db3849e65710dbe0`, SHA-1 `ba3ca0d2eb5674ffc49de1c4dcfebea6c09dcc50`): `Sim City.tzx` (49 699 bytes, md5 `e3b6d8c7eb51fe886626cfc602514a79`), ZXDB download 28075, source type "O" (original release); its archive info: "Sim City", "Maxis", "Infogrames", 1990, "9.99 cass/14.99 disk", "Custom Normal Speed", "Perfect TZX sampled from the original cassette by Church of the Latter-Day Speccy". A BASIC, a 512-byte loader that decrypts itself with the R register, and three headerless, encrypted ROM-speed blocks with flag `$00` (the screen, `$6B00-$FE00`, `$4000-$501F` moved to `$5B00`) ([doc 3](docs/03-build-and-load.md#31-the-tape-block-by-block)) |

## Other releases and copies

Every copy of the local collection (`software/zxdb`, `software/zxart.ee-offline`; `software/games` and
`zxart.ee-delta` hold none) and the TOSEC pack `packs/archive.org/the-spectrum-tosec-knobchez-2026` was copied
unchanged into `work/candidates/<source>/` (`work/stage1/candidates.md5`) and compared block by block and file by file
with the original's loader, its three blocks as stored and decrypted (`tools/decrypt_tape.py`) and the game image
`$5B00-$FDFF` by `tools/media_compare.py` (`work/stage1/media-compare.tsv`, [WALKTHROUGH 0](WALKTHROUGH.md#0-the-medium)).
Copies with the same md5 are listed once.

| Copy | What it is | How it differs from the original |
| --- | --- | --- |
| TOSEC `(FR)(en) - 40670.tzx`, zxart `(EN).tzx` (md5 `e3b6d8c7eb51fe886626cfc602514a79`) | the original's TZX | the same file as in `orig/` |
| TOSEC `(FR)(en)[a] - 40673.tzx` (md5 `da75365398ab2e79c5883dbd6d497811`, "File created by OmikroN Software 1997") | an older TZX of the original | the same seven data blocks byte for byte; every pause 1000 ms, a shorter archive info |
| `zxdb/SimCity(ErbeSoftwareS.A.).tzx.zip` (ZXDB 28078, source "R"; md5 `c90457a2fd34b36c7e5a77421fc0cd12`); TOSEC `(Erbe)(ES)(en)[re-release] - 40668.tzx` = zxart `(EN)[a 1990 Erbe Software S.A.].tzx` (md5 `0ab206ecc717b6d15ff9b977c4fb9d6a`) | the Spanish re-release (Erbe, D.L. M-23336-1990) | no cipher: the screen, code1 and code2 decrypted byte for byte, under standard headers; a 316-byte BASIC loads an anti-drug screen first ("No juegues con tu vida", FAD), the game screen to `$8000` and copies it with 13 poked bytes at 30000, then code1 at 27392 and code2 at 16384, `RANDOMIZE USR 20480` |
| `zxdb/SimCity.tap.zip` (ZXDB 28077, source "++"); TOSEC `(FR)(en) - 40669.tap` = zxart `(EN).tap` = `(EN)[h Illusion Group].tap` (md5 `f504f0f4336a5822fcef3aa34368afb2`) | a crack (Illusion Group) | BASIC "SIM_CITY", 3022 bytes at `$C350` and 23 160 bytes at `$6A77`: packed, no run of 256 original bytes |
| TOSEC `[a] - 40672.tap` = zxart `(EN)[h].tap`; `[h Baradaev Igor]`, `[h Bill Gilbert]`, `[h Breatheater]`, `[h Csl]`, `[h F.C.A]`, `[h Rmc]` (TOSEC 40676-40681 = zxart) | cracks of one family | code2 decrypted byte for byte (4128 bytes), the rest in a packed 19 059-byte block (longest original run 760 bytes); `[a]` stores code2 otherwise |
| TOSEC `[h Prospekt][tr ru] - 40682.tap`, `[h Zx-Profi][tr ru] - 40683.tap` (= zxart) | Russian translations on the same crack | as above, with the texts translated; Zx-Profi re-blocks code2 |
| TOSEC `[h Atossoft] - 40675.tzx` = zxart `(EN)[h Atossoft].tap` | a crack (Atossoft) | the screen decrypted; the game split into a 7808-byte and a 34 432-byte block (the second a turbo block, TZX id `$11`) with runs of 5440 and 16 518 original bytes |
| `zxdb/SimCity.dsk.zip` (ZXDB 28076, source "O") = zxart `(EN)(128K).dsk` | the +3 disk release | a boot sector of its own (sector ids `$41-$49`, no CP/M directory; it pages with `$7FFD` / `$1FFD`) that reads the game by raw sectors; runs of the tape image up to 19 810 bytes, the rest differs or is packed; not run in stage 1 |
| TOSEC `- 40671.z80` | a snapshot | `$5B00-$FDFF` differs from the image in 88 bytes |
| TOSEC `[a] - 40674.z80` | a snapshot of a later state | 39 413 of 41 728 bytes differ |
| zxart `(EN)(128K, KM)[h 2005 Velesoft].sna` | a 128K snapshot with a Kempston mouse patch (Velesoft) | `$5B00-$FDFF` differs in 176 bytes |
| zxart `(EN)(KM)[h 2010 TomCaT, Velesoft].scl` | a TR-DOS conversion of the mouse version | packed, no run of 256 original bytes |
| zxart `[h 1992 Mike Studio]`, `[h 1993 RSSoft]`, `[h 1994 Aleksandr Maryshev, Viktor Maslo]`, `[h 1994 Discovery Ltd]`, `[h 1994 MI&DI Ltd, LV]`, `[h 1994 Pavel Kupriyanov]`, `[h 1997 Computer Monster]`, `[h Alex Rex]`, `[h Chip]`, `[h Decsoft]` (`.scl`) | TR-DOS conversions | packed or re-blocked: Pavel Kupriyanov holds a 21 637-byte run of the image, RSSoft 9566 bytes, Chip and Alex Rex code2 whole, Decsoft the screen whole; the others no run of 256 bytes or short ones |
| zxart `[tr RU 1992 MI&DI Ltd]`, `[tr RU 1993 Chip]`, `[tr RU 1993 KSA, VAV Corp, Apuhtin F.]`, `[tr RU 1994 Hacker Oleg]`, `[tr RU 1994 MI&DI Ltd, Igor Kiselev]`, `[tr RU 1995 Stars of Keladan]`, `[tr RU 1995 Topsoft]`, `[tr RU 1996 Maxsoft, Alexey Kuznetsov]` (`.scl`) | Russian translations on TR-DOS | runs of the image up to 19 981 bytes (MI&DI 1992), 16 389 (KSA), 11 088 (MI&DI 1994); the rest packed |
| zxart `Lemmings & Sim City.trd` | a two-game compilation disk | no run of 256 original bytes: packed |
| `zxdb/Sim City (1990)(Infogrames).pok` | the POKE file | "Infinite money": 26241,0 and 26242,0 (`$6681-$6682`, the `SBC HL,DE` of the shared 24-bit subtraction at `$6680`; [WALKTHROUGH 6.2](WALKTHROUGH.md#62-the-city-map-and-the-state)) |

The original is the Infogrames tape: ZXDB marks it the original release, its archive info says it was sampled from
the original cassette, its loader is the protected one that every other copy removes, and every other tape is the
same three blocks decrypted (Erbe), a crack, a translation, a conversion or a snapshot.

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
. work/env.sh
python3 ../../kit/mkgame.py --case . --install    # src/game/*.asm from src/game/game.ann: "assembled: identical to the original image"
python3 ../../kit/refdocs.py --case .             # docs 11 and 12 from the .ann and the recordings
sh tools/build.sh $SJASMPLUS                      # build/SimCity.tap, encrypted as the tape, against build/orig.tap: "identical"
python3 tools/res_formats.py check                # the 54 editable resources: "0 bad"
```

`python3 tools/image.py work/mkgame/original.bin` builds the game image at the entry from the tape alone.
