# Tujad (Ariolasoft UK, 1986)

State: complete 2026-11-10 (two review rounds). The tape rebuilt byte for byte from the annotated source and `src/res`; docs 01-12
(12 documents, 68 figures, 31 animations, 8 WAVs, 73 mermaid diagrams), counted with
`ls docs/[0-9][0-9]-*.md | wc -l; for e in png gif wav; do find docs -name "*.$e" | wc -l; done; grep -h '^```mermaid' docs/*.md | wc -l`.

| | |
| --- | --- |
| Machine | 48K |
| Profile (AGENTS.md 4.0) | arcade, flip-screen maze shooter: 102 rooms in an 8 x 16 grid of room numbers (+1 east, +8 south), each drawn from its record through the room table at `$DB53`, 26 slots pointing at one empty record ([WALKTHROUGH 6.1](WALKTHROUGH.md#61-the-screens)); sprites XORed onto the screen by the IM 2 handler `$95D0` from a list the main loop builds at `$FF01` (8-byte entries with a collision flag), enemies from pre-shifted buffers `$6708-$6858` and graphics shifted in place ([doc 2.6](docs/02-architecture.md#26-the-sprites-first-look)); a main loop `$6911` that waits for the interrupt twice a pass (`EI; NOP; HALT` at `$796B`) and runs its work with interrupts off (DI at `$796E`): 2 interrupts a pass, 3 when the work overruns, and an INT that falls in the work is lost, so the game takes about 0.87-0.96 interrupts a frame (0.87 over `c1`'s play, 0.92 over `rzx-010000`, 0.96 in room 102; [doc 4.7](docs/04-game-loop.md#47-passes-and-interrupts-a-frame), [doc 10.12](docs/10-gameplay-logic.md#1012-random-the-energy-timer-and-the-rzx-drift)); the pause loops with interrupts off, so nothing moves and the energy does not drain ([doc 5.10](docs/05-controls.md#510-pause-the-interrupt-stops)); controls read in the interrupt (keyboard, cursor, Kempston); the beeper by the game's own toggle loops in the main loop (ticks, tones, sweeps; [doc 9](docs/09-sound.md)); no gravity: the droid hovers, moving up or down only on the keys ([doc 10.1](docs/10-gameplay-logic.md#101-the-droids-movement)); a shield (down held alone) that blocks the touch test and drains the energy 25 times faster ([doc 10.3](docs/10-gameplay-logic.md#103-the-shield)); energy and lives in BCD, a life lost when the energy runs out or at once on a hazard; the 50 ED pieces dealt by an odd number (1-31) of one-slot rotations of the items, 16 possible deals for the first game after loading ([doc 10.9](docs/10-gameplay-logic.md#109-newgame-and-the-deal)); the win: all 50 ED pieces (the ten EdFlags bytes `$1F`), then back in room 84 ([doc 10.10](docs/10-gameplay-logic.md#1010-the-goal-and-the-win)); no hi-score table; no packer, no cipher, no turbo loader ([doc 3](docs/03-build-and-load.md#31-the-tape-block-by-block)) |
| Authors | Orpheus Ltd: Andy Green, Jeff Philips, Stuart J. Ruecroft (ZXDB 5448, team "Orpheus Ltd"); the image holds a copyright line "1986 ORPHEUS LTD" (`$8D85`) that the menu never prints |
| Release | ZXDB 5448, release 0: Ariolasoft UK Ltd, September 1986, a maze arcade game for one player ("Arcade Game: Maze"). ZXDB's note: Orpheus planned to publish it themselves in September 1985 for £8.95 and never did; Ariolasoft published it about a year later. Release 1: the Dro Soft re-release (Spain, 1986). Official ports: Amstrad CPC, Commodore 64, MSX (ZXDB `ports`). The stage 1 brief named Ocean as the publisher; ZXDB, the TZX's archive info and the menu say Ariolasoft UK and Orpheus |
| Original | `orig/Tujad.tzx.zip` (md5 `08aa65c6783400f7b3ac66b880f1289e`, SHA-1 `321402712b8893a52fcd6ae3a9e2ae1c3999ba5a`): `Tujad.tzx` (md5 `7d3e3deef1c645ac1b57b3527be84f57`, SHA-1 `ee79958f2b8ca38077221060240ee2466b6d8248`), ZXDB download 33911, source type "O" (original release), tape code AS22052, barcode 5013538220524; its archive info: "Orpheus Ltd / Ariolasoft UK Ltd", "£8.95", "Original", "TZXed by Thomas Franke". A BASIC loader, a CODE block (the loading screen and a 32-byte stub at `$5B00`) and one headerless ROM-speed block of 40 256 bytes (`$60C0-$FDFF`); no turbo, no packer ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)) |

## Other releases and copies

Every copy of the local collection (`software/zxdb`, `software/zxart.ee-offline`; `software/games` and
`zxart.ee-delta` hold none) and the TOSEC pack `packs/archive.org/the-spectrum-tosec-knobchez-2026` (for the copies
the first two lack) was copied unchanged into `work/candidates/<source>/` and compared block by block and file by
file with the original's two data blocks by `tools/media_compare.py` (`work/stage1/media-compare.tsv`,
[WALKTHROUGH 0](WALKTHROUGH.md#0-the-medium)). Copies with the same md5 are listed once.

| Copy | What it is | How it differs from the original |
| --- | --- | --- |
| `zxdb/Tujad.tap.zip`: `TUJAD.TAP` (ZXDB 33912, scheme "undetermined"; md5 `200c35cb8984a40257dd8b317263d752`; = zxart `(EN).tap`, TOSEC `- 47896.tap`) | a TAP conversion | the same CODE and game blocks byte for byte; the BASIC is 555 bytes, not 88: a machine-code loader in DATA lines poked to 65100, which loads the CODE block's header to `$8000`, the CODE block to `$4000`, the game block, then waits for a key and jumps to `$6300` |
| `zxdb/Tujad(DroSoft).tzx.zip` (ZXDB 143623, release 1; md5 `c69e9cae40f414609a6780182ca7302e`; = zxart `(EN)[a 1986 Dro Soft].tzx`, TOSEC `- 47909.tzx`) | the Spanish re-release (Dro Soft; archive info "D.L.:M-32142-86") | a 95-byte BASIC (the same commands, `BORDER 0` added, LINE 0); the CODE block is cut to 6935 bytes (the stub's first 23 bytes: the loader is whole, the SAVE stub is cut); the game block differs in 296 bytes, all texts translated into Spanish (`$63D9-$65A2` the messages, `$8D42-$8D82` the menu, `$9072-$908A` "HAS COMPLETADO UN % DE TUJAD") |
| TOSEC `[a3] - 47900.tap` (md5 `d16ea998a08ec6745731727040f64068`; WoS's older `TUJAD.TAP`) | a TAP of the original | the same BASIC and CODE blocks; the game block is stored 40 258 bytes long: the 40 256 bytes, then `$79` (the original block's parity byte) and a stray `$E0` |
| zxart `(EN)[h2].tap`, `(EN)[h3].tap`, TOSEC `[a] - 47902.tap` (md5 `b85d3e0f38eb8f4d327d6281b28c13f0`, `dfa51bde42dce41aca7f3454b2499fc1`) | cracks | a 142-byte BASIC, a 5346-byte `screen$` block at 28350 (the loading screen in another form, not the original's bytes), the game block byte for byte as a headed "code" block at 24768 (`$60C0`); the two differ only in a header's param2 |
| zxart `(EN)[h].tap` = TOSEC `[a4] - 47901.tap` (md5 `442d55bffce26725ddc58cb9c01e421d`) | a crack | as `[h2]`, and one game byte changed: `$F89B` `$07` -> `$20` |
| zxart `(EN)[h Sinclairsoft].tap` (md5 `63933cdf1bce841500e242ae8c1a5c1f`) | a Russian translation (Sinclairsoft) | a `screen$` block as `[h2]`; the game block at the same address differs in 565 bytes: the texts in transliterated Russian ("HAYALO MICCII", "KLAVIWI") and characters of the font (`$E032` on) |
| zxart `(EN)[h Kis].tap`, `(EN)[h Prospekt].tap`, `(EN)[h Senator Ltd.].tap` | cracks; Kis and Prospekt Russian translations (TOSEC `[tr ru]`) | other loaders (Prospekt's blocks have flag `$7F`); the game re-blocked and partly packed: the longest run of original bytes is 5853 bytes (Kis, Senator) or 535 (Prospekt) |
| TOSEC `[a] - 47903.tzx` (md5 `292e5e78537a6b6fced5abd9cee50084`, "Tujad (19xx)(Orpheus)[Modified]" in older TOSEC sets) and `[a2] - 47899.tap` (md5 `eae91d9d2a4284f7c5eb8cfb4b52e850`, the same blocks) | a snapshot of a game in progress saved to tape | a BASIC with machine code in a REM (LINE 20, `RANDOMIZE USR` PROG+5) loads four headerless blocks: the screen (6916 bytes at `$4000`), `$61A8-$AFC7`, `$AFC8-$FFFF` and 1704 bytes at `$5B00` holding the registers it restores; the game area differs from the original in 4154 bytes of state, and the status text reads "YOU HAVE COMPLETED  2% OF TUJAD" (`$9072`) |
| TOSEC `- 47898.z80`, `[a] - 47904.z80` | snapshots | `$60C0-$FDFF` equals the game block (`[a]`) or differs in 20 bytes of variables (`47898`) |
| `zxdb/tujad.rzx` (ZXDB 161527, "Recorded by Rafal", Spectaculator) | an input recording of a whole game | its start snapshot's `$60C0-$FDFF` differs from the game block in 20 bytes of variables; 80 680 frames, played on unreal-ng with no desync ([WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)) |
| zxart `(EN)[h 1993 T&S Soft].scl` | a TR-DOS conversion | the game block byte for byte as file `t2.C` (start 24768) |
| zxart `(EN)[h 1993 Andrey Malyshev].scl` | a TR-DOS conversion | one BASIC file with the game block byte for byte at offset 512 |
| zxart `(EN)[h 1994 Mac Buster].scl`, `[tr RU 1995 Hacker Sanek].scl` | TR-DOS conversions (the second Russian) | one file each, with long runs of the game (28 834 and 20 361 bytes) |
| zxart `(EN)[h 1996 Perestroika Software].scl`, `[h 2010 SG-Team].scl`, `[tr RU 1992 Studio K&S].scl`, `[tr RU 1992 Studio K&S, Korund].scl`, `[tr RU 1995 Energy Star Company].scl` | TR-DOS conversions, packed (three Russian translations) | one file each, no run of 256 original bytes: packed |
| zxart `(EN)(GS)[h 2000 Fion].scl` | a General Sound version (Fion, 2000; "GS 512K") | five large files; packed |
| zxart `Tujad Crack Intro.trd` (Demoscene, 1994) | a crack intro | only the intro, no game |

The original is the Ariolasoft tape: ZXDB marks it the original release, its archive info says "Original", and every
other tape is a conversion of its blocks (the TAP of the same entry, the WoS TAP), a translation (Dro Soft,
Sinclairsoft, Kis, Prospekt), a crack or a memory snapshot. The Dro Soft re-release is the same game block with its
texts translated.

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS]     # builds build/Tujad.tap and compares it with the original's blocks byte for byte
```

The game source is `src/game/*.asm`, written by `kit/mkgame.py` from `src/game/game.ann`; the resources are
`src/res/` (`src/res/README.md`).
