# 3. Build and load

What this covers: the medium block by block, the Hewson loader, the packed loading screen, the move of the game into
place, and the source build. It rests on the static decode of the tape (`tools/tzxblocks.py`,
`tools/basic_list.py`, `tools/xorchain.py`, `tools/picy.py`) and on one recording ([Terms](README.md#terms)):

- `c1`: power-on with `Exolon.tzx`, 48K, the load (12 700 frames), then 16 000 frames of seeded random play
  (`work/c1`, WALKTHROUGH 1). The emulator's fast load took the two ROM-loaded blocks (BASIC and loader) by frame
  250; the Hewson loader's blocks played at signal speed. Every frame number here is a `c1` frame.

`python3 tools/check_load.py --work work/c1` reads `c1`'s memory at each stage's entry and compares it with the
static decode (3.5).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - the tape as a picture (blocks, times) -->
<!-- - an animation of the loader's decryption and of the screen unpack (`kit/memanim.py`) -->
<!-- - the build (mermaid) -->

## 3.1 The tape

The reference medium is the "perfect TZX" of the Hewson release (`orig/Exolon.tzx.zip`; the TZX md5
`7ba525e945808b0031f479dfb6fb2fd5`). Its archive-info block (`$32`) names the game, Hewson Consultants, Raffaele
Cecco, 1987, the price 7.95, the loader "Hewson II", and "Perfect TZX sampled from the original cassette by Church
of the Latter-Day Speccy".

`python3 tools/tzxblocks.py list work/media/tzx/Exolon.tzx`:

| TZX block | Kind | Name, fields | Bytes | Loads at | Pause | Plays for |
| --- | --- | --- | ---: | --- | ---: | ---: |
| 0 | `$32` archive info | | | | | |
| 1 | `$10` header | Program `exolon`, LINE 0, length 81 | 17 (+2) | | 1007 ms | 5.09 s |
| 2 | `$10` BASIC | | 81 (+2) | PROG | 999 ms | 2.43 s |
| 3 | `$10` header | Bytes `exolon`, start 64512 (`$FC00`), length 768 | 17 (+2) | | 1003 ms | 5.10 s |
| 4 | `$10` CODE | the loader | 768 (+2) | `$FC00-$FEFF` (ROM LD-BYTES) | 1008 ms | 6.37 s |
| 5 | `$10` header | type 42 (`$2A`) `exolon`, start `$8000`, length 4096 | 17 (+2) | | 1008 ms | 5.09 s |
| 6 | `$10` data | the packed loading screen and its unpacker | 4096 (+2) | `$8000-$8FFF` (the Hewson loader) | 1011 ms | 24.84 s |
| 7 | `$10` header | type 42 (`$2A`) `exolon`, start `$6590`, length 37536 | 17 (+2) | | 1003 ms | 5.10 s |
| 8 | `$10` data | the game | 37536 (+2) | `$6590-$F82F`, then moved to `$6D60-$FFFF` | 0 | 204.35 s |

- Every block is a standard-speed `$10` block with the ROM's timings (pilot 2168, sync 667 / 735, bits 855 / 1710
  T), 8063 pilot pulses before a header and 3223 before data; all eight checksums are good.
- The signal, pauses included, takes 265.4 s, 13 270 frames at 50 Hz (the script's total).
- Blocks 5 and 7 are headers of type 42, not a type the ROM's LOAD takes; the Hewson loader reads them and checks
  the 42 (3.3). The second word of each header (the ROM's "param 2") holds `$4000` and `$6784`; the loader does
  not read it.

`orig/Exolon.tap.zip` holds a modified copy, not the release. Its blocks 4-8 are those of the TZX except the
loader, which is stored already decrypted (equal byte for byte to the output of 3.3). Its BASIC (two lines, 457
bytes) clears like the original, loads the loader, then `POKE 64659,0`, `POKE 65105-65107` (`JP $FC99`), POKEs 28
bytes of a DATA line to `$FC96-$FCB1` (a jump into the ROM's LD-BYTES at `$0562` and a patch of the loader's
`LoadFile`), and enters at `$FE3A` (65082), past the decryption. The case keeps it as found; the build targets the
TZX.

## 3.2 The BASIC (TZX block 2)

`python3 tools/basic_list.py work/media/exolon.bas`:

```text
   10 BORDER 0: PAPER 0: INK 7: CLEAR 25999: LOAD "" CODE : RANDOMIZE USR 64512
   20 REM *************            (length word 98: runs 84 bytes past the program's end)
```

The same program as Zynaps' but for the `CLEAR` (Zynaps: 32767): RAMTOP goes to `$658F`, one below the code
file's start. `LOAD "" CODE` takes the loader to `$FC00` (the header's address), `RANDOMIZE USR 64512` enters it.

## 3.3 The loader (TZX block 4)

The loader is Zynaps' Countdown II (Zynaps [3.3](../../zynaps/docs/03-build-and-load.md#33-the-loader-tzx-block-4-an-xor-chain-over-itself)):
19 plain bytes that decrypt the rest with one forward XOR chain, each byte XORed with the next as the tape holds
it. Here the chain is 656 bytes long (`LD BC,$0290`), `$FC13-$FEA2`; Zynaps' was 652. `tools/xorchain.py` writes
the plain loader; its first instruction at `$FC13` is `JP $FE3A`.

Against Zynaps' decrypted loader, 105 of the 768 bytes differ:

- the countdown's screen addresses: the four digits at `$50FB-$50FE` (row 23, columns 27-30) and their attribute
  cells `$5AFB-$5AFE`, where Zynaps' were at columns 1-4: the counter is drawn into the strip of boxes at the
  bottom right of the loading screen;
- the stages at `$FE3A` (below), four bytes longer;
- `LoadFile` (`$FE71`), which now refuses a header whose first byte is not 42 (`$2A`) and waits for the next one.

The stages, decoded from the plain loader:

```text
FE3A  DI
      LD HL,$5800 / LD DE,$5801 / LD BC,$02FF / LD (HL),0 / LDIR   ; every attribute black
      CALL LoadFile        ; header 42, then 4096 bytes at $8000
      CALL $8001           ; unpack the loading screen (3.4)
      CALL LoadFile        ; header 42, then 37536 bytes at $6590
      LD HL,$FE5F / LD DE,$5B00 / LD BC,18 / LDIR / JP $5B00       ; MoveStub to the printer buffer
5B00  LD HL,$F82F / LD DE,$FFFF / LD BC,$92A0 / LDDR               ; the game to $6D60-$FFFF
      LD SP,$6D5E
      EI
      JP $6D60
```

The game starts at `$6D60` with the stack below it; `$6590-$6D5F` keeps what the move left there (the first 2000
bytes of the code file as loaded). `tools/image.py` writes the image as the move leaves it, `$6D60-$FFFF`.

## 3.4 The loading screen (TZX block 6)

The 4096 bytes at `$8000` have Zynaps' `picy` layout (a zero byte, `JR` over a header of three stream offsets and
the border colour, the unpacker) and the same format: `tools/picy.py unpack` gives the 6912 bytes of the screen
(literals up to `$8BC0`, masks up to `$8F0C`, flags up to `$8F78`, border 0). The packer is Zynaps' rule, a byte
marked as a repeat whenever it equals the byte before it: `python3 tools/picy.py check` packs the unpacked screen
again and gets the tape's three streams exactly (2850 literals, 844 masks, 108 flags). The unpacker is Zynaps' byte
for byte: `src/tape/picy.asm`, Zynaps' source with only the padding changed, assembles to the tape's block (3.6).
The streams are shorter than Zynaps', so 136 zero bytes fill the block's end where Zynaps' had 6.

The screen: the EXOLON logo in yellow among dithered planets on black, HEWSON at the bottom left, a strip of boxes
at the bottom right that the countdown fills.

## 3.5 The stages in `c1`

`re_session.py stages --work work/c1` lists the code arrivals; each is a stage of 3.3:

| Stage | Entered at | Frame, T | Written by | Entered from | What |
| --- | --- | --- | --- | --- | --- |
| 0 | `$FC00` | 250, 34 665 | `$0802` (the ROM's LD-BYTES, fast load) | `$34BB` (`USR`) | the loader as the tape holds it |
| 1 | `$FC13` | 251, 4 431 | `$FC0B` (the XOR chain) | `$FC11` | the decrypted loader |
| 2 | `$8001` | 1 808, 61 301 | `$FCE7` (the loader's LD-BYTES) | `$FE4B` | the picy unpacker |
| 3 | `$4000` | 1 808, 61 434 | `$8017` | `$801A` | two bytes the unpacker writes into the screen and calls to find its own address (Zynaps 3.4) |
| 4 | `$5B00` | 12 364, 38 072 | `$FE5A` | `$FE5C` | MoveStub |
| 5 | `$6D60` | 12 376, 62 848 | `$5B09` (the LDDR) | `$5B0F` | the game |

`tools/check_load.py` at those moments:

| Read | At | Bytes that differ from the static decode |
| --- | --- | --- |
| `$FC00-$FEFF` | 251:4431 | 0 of 768 (`xorchain.py decrypt`) |
| `$8000-$8FFF` | 1808:61301 | 0 of 4096 (block 6) |
| `$4000-$5AFF` | 12364:38072 | 24 of 6912 (`picy.py unpack`), all in `$51FB-$56FE`: row 23, columns 27-30, the countdown's digits drawn over the picture |
| `$6590-$F82F` | 12364:38072 | 0 of 37536 (block 8 as loaded) |
| `$6D60-$FFFF` | 12376:62848 | 0 of 37536 (`tools/image.py`) |

The game is entered 12 376 frames into `c1`, about 4 minutes 8 seconds of the load. The unpacker is entered in
frame 1808, so the picture stands for about 10 568 frames, the code file's load.

## 3.6 The build

`tools/build.sh` writes `build/Exolon.tzx` from the sources and compares it with the TZX in `orig/Exolon.tzx.zip`:

| TZX block | Source | Tool |
| --- | --- | --- |
| 0 | `src/tape/exolon-tzx.txt` (the archive-info strings) | `tools/tzx.py` |
| 1, 3, 5, 7 | `src/tape/exolon-tzx.txt` (the headers: types 0, 3, 42, 42, names, addresses, parameter 2, pauses) | `tools/tzx.py` |
| 2 | `src/tape/basic.asm` | sjasmplus |
| 4 | `src/tape/loader.asm` (the loader in the clear) | sjasmplus, then `tools/xorchain.py encrypt` |
| 6 | `src/tape/picy.asm` and `src/res/screens/loading.scr` | `tools/picy.py pack`, then sjasmplus |
| 8 | `src/game/game.asm` (written by `kit/mkgame.py` from `src/game/game.ann`) | sjasmplus |

`src/tape/loader.asm` is Zynaps' loader source with the changes of 3.3: the counter's screen addresses
(`CountRow` `$50FF`, `CountAttr` `$5AFB`), no `LD SP,$FFFF` at `Start` (the stack stays the BASIC's), the game's
addresses in `MoveStub`, the type check in `LoadFile` (`CP 42`), and 50 zero bytes before the leftover tail where
Zynaps' had 54. `tools/tzx.py` is Zynaps' with a header form for the type-42 headers.

```text
$ rm -rf build && tools/build.sh
build: Exolon.tzx identical to orig/Exolon.tzx.zip's Exolon.tzx
```
