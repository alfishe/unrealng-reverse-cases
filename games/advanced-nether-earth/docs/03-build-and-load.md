# 03. The media and the load 

Two media: the Final Cut disk of 2017 (`orig/ANE_FC.TRD`, the case's original) and the 1998 release (the TOSEC
SCL, extracted to `orig/Advanced Nether Earth (1998)(Eternity Industry)(128K)(RU).scl`, sha256 `7e236662...`). Both boot on Pentagon 128 with TR-DOS 5.04T; the
recordings were made from power-on on unreal-ng (`PENTAGON`, 128 K), the load through the 128 menu (`cs 7` to
TR-DOS, `ENTER`, then `R` `ENTER` for `boot`, or `RUN "A_NETHER"`): input scripts in `work/stage1/inputs/`.

Every address below is from the recordings, the arrivals listed by `re_session.py stages` (the code the recording
wrote and then ran: `work/stage1/c1/stages.txt`, `s1/stages.txt`, `s2/stages.txt`), not from a reading of the code
alone. Frames are the recording's.

## 1. The Final Cut disk (2017): BASIC, Hrust 1, the Final Cut alone

The catalogue: `ane_fc.B` (BASIC, 174 bytes, 56 sectors from track 1 sector 0) and `boot.B` (33 bytes, track 4
sector 8); label `ane_fc`, 2487 sectors free.

| Stage | Where, when | What |
| --- | --- | --- |
| `boot` | | `10 RANDOMIZE USR 15619: REM : RUN "ane_fc" LINE 10` |
| `ane_fc` BASIC | arrival 3, `$5D4F`, frame 1909 | line 10033 (autostart 10000): machine code in the line sets `SP=$5FFF`, pushes the returns `$61A8`, `$3D13`, `$15FF`, `$33C3`, clears the screen with LDIR and calls TR-DOS `$3D13` with `C=5`: 55 sectors to `$61A8`. After the line: `KALANTAJ KONSTANTIN. UKRAINE. KRIVOY ROG. 10.05.2017` |
| the read | arrival 4, `$61A8`, frame 1977 | written `$61A8-$98A7` by TR-DOS `$3FEC` |
| Hrust 1 | arrival 5, `$FE4C`, frame 1977 | `$61A8` (DI) copies the depacker (`$DE` bytes) to `$FE4C` and the 6 last bytes to `$FF2C`, moves the packed block up to end at `$F76C` (LDDR) and unpacks it to `$6060-$F76C`. Packed block: `HR`, unpacked length `$970D`, packed `$3583`, the 6 last bytes: Hrust 1 (Dmitry Pyankov) |
| the Final Cut | arrival 7, `$DB00`, frame 2038 | `$61BA` copies `$C000-$F577`; then the scroller code (`$E251`, `$E636`, `$E6C7`: self-modifying writes) |

Pages: the load runs with the ROM's default paging; the image is `$6060-$F76C` of the 64 K view (bank 0 at
`$C000`). Dumps: `work/images/fc-unpacked-*` (frame 2038, at arrival 7) and `fc-end-*` (frame 16000).

## 2. The 1998 release (SCL)

| File | Size | What |
| --- | --- | --- |
| `A_NETHER.B` | BASIC, 2808 bytes, 255 sectors with what follows | the loader: an UltraXOR v1.2 protection layer (the text `PARACELS` in it) |
| `a_nether.E` | 182 sectors | the packed blocks read by sector (the text `HRUM v3.5 by Dmitry Pyankov` in it) |
| `nether.N` | start 55595, 9941 bytes | read by the loader (not followed further in stage 1) |
| `NETHER+.W` | 38912 bytes / 9143 | a text document in CP866: history, what is new, credits (`src/res/text/nether-plus-w.txt`) |

The load, from `s1` (power-on to the boot menu) and `s2` (on to play):

| Arrival | At, frame | Written by | What |
| --- | --- | --- | --- |
| 3 | `$5D97`, 2031 | `$19F7` (ROM LOAD) | the BASIC with its code, `$5D2D-$6833` |
| 4-6 | `$7705` / `$7758` / `$77D7`, 2035 | `$5DC1`, `$7754`, `$77D3` | UltraXOR: `$7705-$813A` decrypted, then two self-decrypting layers |
| 7 | `$6221`, 2125 | TR-DOS `$3FEC` | the loader proper, `$6161-$8D60` |
| 8 | `$5B89`, 2125 | `$660F` | a resident helper `$5B89-$5BFF` (paging and copy; it writes most later arrivals: `$5B95`, `$5BDF`) |
| 10, 13 | `$C000`, 2154 / 2156 | `$6626`, `$664D` | blocks unpacked into the `$C000` page: the intro (Eternity logo, scroller) |
| 28 | `$6D24`, 3403 | `$5B95` | the boot menu (`1-Game 2-Help 3-NOT used`) |
| 29-31 | `$62B8` / `$9C40` / `$C000`, 6601-6804 | TR-DOS `$3FEC` | after `1`: the game's blocks read, `$62AA-$65FF`, `$9C40-$A93F`, `$6060-$CCFF` |
| 32, 33 | `$FE4C`, 6804 / 6958 | `$C00F`, `$606F` | HRUM 3.5's depacker (`$77` bytes, `$FE4C-$FEC2`) copied up and run, per block |
| 45-48 | `$C000` / `$FE4C`, 7372-7395 | TR-DOS, `$625E`, `$C00F` | more blocks read to `$C000-$FAFF` and unpacked |
| 49, 50 | `$A5DA` / `$D8E1`, 7452 | `$FE58` (the depacker) | the game's start: ANE's new entry `$A5EF` area |
| 63 | `$D566`, 8627 | `$FE58` | NE's `PlayInterrupt`, entered from `$6969` (ANE's new IM 2 `Handler`) |

The packer of the game and of the Final Cut is HRUM 3.5 (Dmitry Pyankov: its string in `a_nether.E`, its name in
the credits of `NETHER+.W`, its 119-byte depacker at `$FE4C`). Bank 6 in play holds the Final Cut packed with HRUM:
it starts `DI; LD ($0000),SP; LD HL,$617F; LD DE,$FE4C; LD BC,$0077; LDIR; ... LD DE,$6060` and moves `$3597`
packed bytes up to end at `$F76C`: the same target `$6060-$F76C` as the 2017 disk's Hrust 1 block.

The pages in play (from the dumps `work/images/scl-play-bank0..7.bin`, frame 11500, and the code that pages them):

| Bank | Role |
| --- | --- |
| 5 | `$4000-$7FFF`: screen, ANE's IM 2 table (`$6800`) and `Handler` (`$6969`), the music glue (`$67B1`), the disk save (`$6905`) |
| 2 | `$8000-$BFFF`: NE's sprites and code from `$A600` |
| 0 | `$C000-$FFFF`: NE's code to `$D7D2`, ANE's font (`$C400`, Cyrillic at `$C500`), NE's world state and map |
| 1 | the PT3 player (`$C005`) and the play music, paged in by the interrupt |
| 3 | the "Dead End" (loss) sequence, `JP $D2EF`, and its tune (starts like bank 1: the same player) |
| 6 | the Final Cut (win), HRUM-packed |
| 4, 7 | loaded blocks, not yet followed (bank 7: a packed block with the same HRUM prologue, target `$9C40`) |

Open for stage 2: the port `$7FFD` writes per arrival (which bank each block went to), the help program's load, the
role of `nether.N`.

## 3. The SCL release against the Final Cut disk

The 2017 disk is not a new version. It holds only the Final Cut block of the 1998 game, with a new BASIC and
Hrust 1 in place of HRUM: on the SCL a win (from a live instance, `EnemyBuildings` `$FD42` poked to 0) plays the
same Final Cut, and the memory then equals the 2017 disk's at its end in `$6060-$F76C` but for a few working bytes
(`$8000-$BFFF` all 16384 bytes, `$6060-$7FFF` 8092 of 8096, `$C000-$F76C` all). See [12](12-claims.md) 4.
The game, the help, the intro and the "Dead End" are only on the SCL.
