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
| 1 | the play music: a ProTracker 2 module and its player (`$C005`; section 4.4, [07](07-sound.md)), paged in by the interrupt |
| 3 | the "Dead End" (loss) sequence, `JP $D2EF`, and its tune (starts like bank 1: the same player) |
| 6 | the Final Cut (win), HRUM-packed |
| 4 | the disk module (save and load, run at `$4000`), HRUM-packed (section 4.3) |
| 7 | the boot program's part that starts the game (HRUM-packed, unpacks to `$9C40`) and the rest of the boot's image |

Stage 2 followed every sector, page and block statically (section 4): the role of bank 4 (the disk module, read
at the boot) and bank 7 (the boot's game starter and its picture), the `$7FFD` writes per stage, and `nether.N` (a
saved game).

## 3. The SCL release against the Final Cut disk

The 2017 disk is not a new version. It holds only the Final Cut block of the 1998 game, with a new BASIC and
Hrust 1 in place of HRUM: on the SCL a win (from a live instance, `EnemyBuildings` `$FD42` poked to 0) plays the
same Final Cut, and the memory then equals the 2017 disk's at its end in `$6060-$F76C` but for a few working bytes
(`$8000-$BFFF` all 16384 bytes, `$6060-$7FFF` 8092 of 8096, `$C000-$F76C` all). See [12](12-claims.md) 4.
The game, the help, the intro and the "Dead End" are only on the SCL.

## 4. The SCL, sector by sector (stage 2)

Stage 2 runs the boot statically: `tools/ane_sim.py` (SkoolKit's simulator with 128 K paging, the 128 and TR-DOS
5.04T ROMs, a WD1793 model reading the SCL, scripted keys) from `RUN "A_NETHER"` to the game's start. It logs every
sector read, every `$7FFD` write and every HRUM depack (the output written to a file). Its frames are its own
(SPACE pressed at frame 1300, `1` at 2000), not the recordings'. Commands: `work/stage2/NOTES.md`.

### 4.1 The disk map

Sector numbers count from `A_NETHER.B`'s first sector across the files (the loader reads by logical sector, and
`A_NETHER.B` starts at logical sector 16: sector k is logical 16 + k). `src/disk.txt` is the same map as the
build's input.

| Sectors | File | Read to (when) | What |
| --- | --- | --- | --- |
| 0-10 | `A_NETHER.B` | `$5D3B` (BASIC `LOAD`) | the BASIC: line 0 holds UltraXOR, line 1 `CLOSE # USR Eternity` (`Eternity` = 23959, `$5D97`) |
| 11-54 | `A_NETHER.B` | `$6161-$8D60` (UltraXOR) | the loader: code `$6161-$62C7`, the intro's block at `$6600` (`src/loader.asm`) |
| 55-71 | `A_NETHER.B` | bank 7 `$DB00` | the "Presents" block (run at `$6600`) |
| 72-86 | `A_NETHER.B` | bank 4 `$C000` | the scroller's block (run at `$6600`) |
| 87-99 | `A_NETHER.B` | `$9C40`, after SPACE | the title picture with its own screen depacker (plain code, not HRUM) |
| 100-211 | `A_NETHER.B` | `$6060` | the boot program: the boot menu and the help (block at `$6060`) |
| 212-254, 255-270 | `A_NETHER.B`, `a_nether.E` 0-15 | bank 3 `$C000-$FAFF` | Dead End's block, the game block's last 914 bytes, the game music's block |
| 271-283 | `a_nether.E` 16-28 | bank 1 `$C000` | the boot music: the PT3 player and a ProTracker 3.1 module |
| 284-347 | `a_nether.E` 29-92 | bank 4 `$C000-$FFFF` | the game block's first 16384 bytes |
| 348-410 | `a_nether.E` 93-155 | bank 6 `$C000` | Final Cut's block; the disk module's block at sector 402 byte 55 |
| 411-436 | `a_nether.E` 156-181 | bank 7 `$C000` | bank 7's boot image (its first part starts the game) |
| 437-475 | `nether.N` | never at the boot | a saved game (CODE 55595 = `$D92B`, 9941 bytes: the disk module writes such a file) |
| 476-511 | `NETHER+.W` | never | the authors' text, CP866 |

All of `A_NETHER.B` and `a_nether.E` is read before the boot menu shows: the menu, the help and the game start run
from memory. The bytes no read reaches (after each block's end in its last sector) are leftovers of the authors'
tools: twice HRUM's own signature `HRUM v3.5 by Dmitry Pyankov / Tel.(38822)-4421-1.Bye!!! / Gorno-Altaisk,
09.01.97`, zeros, or older sector contents (`src/res/disk/`).

### 4.2 The boot, stage by stage, with the `$7FFD` writes

| Frames (sim) | Code | `$7FFD` (writer) | What |
| --- | --- | --- | --- |
| 0-29 | UltraXOR `$5D97`, its layers at `$7705-$813A` | `$10`, `$11`, `$13`, `$14`, `$16`, `$17` (`$5E69`) | the loader read (sectors 11-54, sector 50 read twice), bank 7 `$DB00`, bank 4 `$C000`; `JP $6221` |
| 29-1172 | the intro (`$6600`, block 1 below) | `$10` (`$66B3`); the loader's IM 2 handler `$16`/`$1E`, back `$10`/`$18` (`$6185`, `$619B`) | the Eternity Industry picture (its block unpacked into bank 7's screen at frame 60) with the tune "MAD NIGHT" |
| 1172 | "Presents" (block 2) | `$17`, `$10`, `$18` (`$620D`, the loader's `SetPage`) | after a white flash; then 20 flashes between screens 5 and 7 |
| 1274-1300 | the scroller (block 3) | `$14` then `$10` (`$620D`) | the credits scroller, `PRESS 'SPACE'` |
| 1300-1405 | UltraXOR again | `$5E69` | SPACE ends the loader (`LoaderEnd`, IM 1, `RET` to UltraXOR's code); the reads of sectors 87-436 follow, their `$7FFD` writes from UltraXOR's reader `$5E69` (the code that starts the title picture at `$9C40` was not traced) |
| 1360-1473 | the boot program | | bank 1's boot music (frame 1360), the boot program at `$6060` (frame 1405, `JP $61A8`), bank 7's image (frame 1473, its depacker at `$5B00`) |
| 1473-2100 | the boot menu, the help | `$11` / `$10` a frame (`$624D`) | the boot program's own paging: its music from bank 1 every frame |
| 2005-2100 | `1`: bank 7's first part at `$9C40` | `$624D` | the game's blocks unpacked: music (bank 1, 2059), Dead End (bank 3, 2071), the disk module (bank 4, 2094), the game (`$6731`, 2100) |
| 2151 | `GameEntry` `$A5DA` | `$11`, `$10` (`$A5E3`, `$A5ED`) | the tune set up, then NE's `Start` (src/game/ane-patches.asm) |

### 4.3 HRUM 3.5 blocks

Every packed part is a self-extracting HRUM 3.5 block (`src/sfx/hrum35.asm`): 31 bytes of set-up, the 119-byte
depacker, the stream. The set-up copies the depacker to `$5B89` (the loader's blocks; this is stage 1's "resident
helper `$5B89-$5BFF`"), `$FE4C` (the game's) or `$5B00` (bank 7's image, which covers `$FE4C`), and RETs into it;
the depacker moves the stream up to end where the output ends (LDDR), unpacks upwards, copies the 5 last bytes it
keeps in its own tail, sets SP (the caller's, or a fixed one) and ends with `RET` or `JP`.

The stream (`tools/hrum.py`): 16-bit flag words read by `POP`, interleaved with the bytes (a word is read as soon
as the previous one's 16 bits are used); the first token is a literal; flag 1 = a literal byte, flag 0 = a match
whose length code is a sequence of 2-bit values (0-2 end it, 3 adds 3 and goes on to 16): code 1 copies 1 byte
from offset -8..-1 (3 bits), code 2 copies 2 bytes from -256..-1 (a byte), code 3 copies 3, code 4 reads the
length from a byte (0 = the end), codes 5-16 copy 4-15; after a length of 3 or more one more flag picks an offset
of 8 bits (-256..-1) or of 12 (4 bits, then a byte). The packer that gives the original streams is greedy: at each
place the longest match within 4096 bytes (2 within 256, 1 within 8, at most 255), the nearest of equal ones, else
a literal; the last 5 bytes go to the tail. `tools/hrum.py pack` reproduces all 13 streams of the SCL byte for byte.

| Block | Lies at (sector+byte) | Runs at, depacker | Unpacks to | Ends |
| --- | --- | --- | --- | --- |
| the intro | 15+159 (in the loader, `$6600`) | `$6600`, `$5B89` | `$6600-$A3AC` | `EI`, `JP $6600` |
| the intro's picture | inside the intro image at `$7537` | `$C000` (bank 7), `$5B89` | `$C000-$DAFF` | `EI`, `RET` |
| "Presents" | 55+0 | `$6600` (`EI` first), `$5B89` | `$6600-$D4A3` | `EI`, `JP $6600` |
| the scroller | 72+0 | `$6600` (`EI` first), `$5B89` | `$6600-$FFFF` | `EI`, `JP $6600` |
| the boot music | 271+0 | bank 1 `$C000`, `$FE4C` | `$C000-$D60E` | `DI`, `RET` |
| the boot program | 100+0 | `$6060`, `$FE4C` | `$6060-$F6D4` | SP `$6060`, `DI`, `JP $61A8` |
| bank 7's image | 411+0 | bank 7 `$C000`, `$5B00` | `$C000-$FFFF` | `DI`, `RET` |
| the game starter | inside bank 7's image at `$C000` | `$9C40`, `$FE4C` | `$9C40-$B78F` | `DI`, `JP $9C40` |
| the game music | 255+48 | bank 1 `$C000`, `$FE4C` | `$C000-$E21A` | `EI`, `RET` |
| Dead End | 212+0 | bank 3 `$C000`, `$FE4C` | `$C000-$FE1E` | `DI`, `RET` |
| the disk module | 402+55 | bank 4 `$C000`, `$FE4C` | `$C000-$CD2B` | `DI`, `RET` |
| the game | 284+0 (16384 bytes) and 251+158 (914) | `$6731`, `$FE4C` | `$6731-$D7D7` | SP `$6731`, `DI`, `JP $A5DA` |
| Final Cut | 348+0 | `$6060` (copied from bank 6 by `GameWon`), `$FE4C` | `$6060-$F76C` | SP `$6060`, `DI`, `JP $61A8` |

The disk module (bank 4) clears the screen, puts its stack at `$5000`, goes back to IM 1 with the BASIC's
registers, silences the AY, copies its `$C065-$CD2B` to `$4000` (the cleared screen) and jumps to IX: `$4000`
loads a game, `$4033` saves one (`GameLoad`, `GameSave` in `src/game/ane-patches.asm`). Its texts are in English
("Wooow ! Whatta cool opt!on !...", "Yah, now just enter da filename:").

### 4.4 What each image is

| Image | Evidence |
| --- | --- |
| the intro `$6600-$A3AC` | the Eternity picture (its own block), "New SoundTrack Player By PHANTOM FAMILY'1996" and the tune "MAD NIGHT BY SYRUS/EI/15.02.98" |
| "Presents" `$6600-$D4A3` | the screen at frame 1240: `work/stage2/screens/presents-f1240.png` |
| the scroller `$6600-$FFFF` | the scroller text of [12](12-claims.md) 2 |
| the title picture `$9C40` (plain) | its depacker (a screen-order LZ: `CALL $0052` to find its own address, output to `$4000`); the screen at frame 1450: `work/stage2/screens/title-f1450.png` ("АДСКАЯ ЗЕМЛЯ", "ADVANCED NETHER EARTH", "ETERNITY INDUSTRY PRODUCTION") |
| the boot program `$6060-$F6D4` | the help menu texts (`OPISANIE IGRY` ...) and the help credits |
| the boot music, bank 1 | "PT 3 Player v1.0 by Nick of GDC", "ProTracker 3.1 compilation of 08.12.96/02:25/*X-MAN-MUSIC*" |
| the game music, bank 1 | "New SoundTrack Player By PHANTOM FAMILY'1996" and a ProTracker 2 module at `$CA45` named "05.03.97/23:41/*X-MAN-MUSIC*": X-Man's "TAIGA" (1997) of zxart.ee 83098 ([07](07-sound.md)) |
| Dead End, bank 3 | "NETHER EARTH (END) by SYRUS/EI", the same SoundTrack player; entered at `$D2EF` |
| Final Cut | the texts of [12](12-claims.md) 4, "PT 3 Player v1.0 by Nick of GDC" |

## 5. The build

`tools/build.sh` writes the SCL from the sources and compares it with the original: **identical, byte for byte**.

1. Nether Earth's game from NE's own source (`games/nether-earth/src/game`, its resources) into `build/ne`, checked
   against NE's image.
2. ANE's game image: NE's bytes with ANE's patches (`src/game/ane.asm`, `src/game/ane-patches.asm`: every changed
   byte, the code ones as named instructions, the texts as bytes with their letters), the Cyrillic font from
   `src/res/gfx/game-font.png`.
3. HRUM 3.5: `tools/hrum.py` packs every image (the original streams exactly), `src/sfx/blocks.asm` assembles each
   block with the set-up and depacker macro of `src/sfx/hrum35.asm`; the two blocks that sit inside other images
   first (`src/images.asm` puts them in).
4. The loader (`src/loader.asm`), the intro's block in it.
5. The disk: `tools/mkdisk.py` from `src/disk.txt` (every byte of every sector from a listed file; the text file
   from UTF-8 to CP866).

Kept as the original bytes (`src/res/disk/README.md`, `src/res/img/README.md`):

- **UltraXOR** (sectors 0-10, `src/res/disk/boot-a-nether-b.bin`): about 70 small layers that decrypt each other
  with keys from the R register and from their own code, ending in a sector reader built on TR-DOS ROM gadgets.
  Re-encrypting needs every layer's key schedule; stage 2 documents its effect (section 4.2) and keeps its bytes.
- **The images other than the game** (`src/res/img/*.bin`: the intro, "Presents", the scroller, the title
  picture, the boot program, bank 7, the two music banks, Dead End, the disk module, Final Cut): the build packs
  them, but they are not yet sources.
- **`nether.N`** (a saved game) and the unread filler bytes.
