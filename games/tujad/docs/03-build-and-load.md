# 3. Build and load

What this covers: the tape block by block, the BASIC line, the 32-byte stub at `$5B00` that loads the game, and
(later) the source build. There is no turbo loader, no packer and no cipher: the game arrives as plain bytes at ROM
speed, so there is no unpack to show. The recording it rests on is `c1` (from power-on, the tape at ROM speed,
[WALKTHROUGH 1](../WALKTHROUGH.md#1-one-recording-from-power-on)).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - the tape on a time line (blocks, pauses, where each lands) -->
<!-- - the load as memory over time (`kit/memanim.py` over c1) -->
<!-- - the build (mermaid) -->

## 3.1 The tape, block by block

The original release (`orig/Tujad.tzx.zip`, `Tujad.tzx`) holds an archive-info block and five standard-speed blocks
(TZX id `$10`). Every one has the ROM's timings: pilot 2168 T (8063 pulses for a header, 3223 for data), sync 667 /
735 T, zero 855 T, one 1710 T. Each starts with its flag (`$00` a header, `$FF` data) and ends with its XOR checksum.

| Block | Kind | Bytes (+2 on tape) | Loads at | Time on tape | Pause after |
| ---: | --- | ---: | --- | ---: | ---: |
| 0 | archive info: "Tujad", "Orpheus Ltd / Ariolasoft UK Ltd", "Andy Green, Jeff Philips", 1986, "Arcade: Maze", "£8.95", "Original", "TZXed by Thomas Franke" | | | | |
| 1 | header: Program "TUJAD", length 88, LINE 10 | 17 | | 5.08 s | 988 ms |
| 2 | the BASIC program, one line (3.2) | 88 | PROG | 2.46 s | 1630 ms |
| 3 | header: Bytes "TUJAD", length 6944, start 32768 (`$8000`) | 17 | | 5.08 s | 987 ms |
| 4 | the loading screen (6912 bytes) and the 32-byte stub | 6944 | `$4000-$5B1F` (`LOAD "" CODE 16384` overrides the header's 32768) | 38.12 s | 1914 ms |
| 5 | headerless: the game | 40 256 | `$60C0-$FDFF` (the stub's `LD IX,$60C0; LD DE,$9D40`) | 212.11 s | 5312 ms |

- The signal lasts 262.85 s, 13 163 frames of the 48K (69 888 T a frame), the pauses not counted.
- The game block ends at `$FDFF`; `$FE00-$FFFF` is filled by the game itself (the IM 2 vector table, doc 4).

```bash
python3 tools/tzxblocks.py list work/media/zxdb-Tujad.tzx/Tujad.tzx     # the blocks and their timings
python3 tools/image.py work/mkgame/original.bin                         # blocks 4 and 5 where the load puts them
```

**The point**: a plain ROM-speed tape of the usual shape (BASIC, screen, game); the only machine code before the game
is the stub at `$5B00` that loads the headerless block with the ROM's LD-BYTES.

## 3.2 The BASIC line and the stub at `$5B00`

Block 2 is one line (`python3 tools/basic_list.py work/stage1/blocks/basic.bin`):

```basic
10 CLEAR 24767: PAPER 0: INK 0: POKE 23624,0: CLS : LOAD "" CODE 16384: RANDOMIZE USR 23296
```

- `CLEAR 24767` puts RAMTOP at `$60BF`, just below the game block (`$60C0`).
- `PAPER 0: INK 0`, `POKE 23624,0` (BORDCR: a black border and lower screen) and `CLS` keep the screen black while
  the picture loads into it.
- `LOAD "" CODE 16384` loads block 4 to the screen and the printer buffer; `RANDOMIZE USR 23296` calls `$5B00`.

The last 32 bytes of block 4 land in the printer buffer, `$5B00-$5B1F` (`z80dasm -g 0x5B00` of
`work/stage1/blocks/b4.bin` from offset 6912):

| Address | Bytes | Instruction | What |
| --- | --- | --- | --- |
| `$5B00` | `37` | `SCF` | carry set: LOAD, not VERIFY |
| `$5B01` | `3E FF` | `LD A,$FF` | the flag of a data block |
| `$5B03` | `DD 21 C0 60` | `LD IX,$60C0` | where the game goes |
| `$5B07` | `11 40 9D` | `LD DE,$9D40` | 40 256 bytes |
| `$5B0A` | `CD 56 05` | `CALL $0556` | the ROM's LD-BYTES |
| `$5B0D` | `C3 00 63` | `JP $6300` | into the game (`$6300`: `JP $68F3`) |
| `$5B10` | `3E FF` | `LD A,$FF` | |
| `$5B12` | `DD 21 C0 60` | `LD IX,$60C0` | |
| `$5B16` | `11 40 9D` | `LD DE,$9D40` | |
| `$5B19` | `CD C2 04` | `CALL $04C2` | the ROM's SA-BYTES: **saves** the same block |
| `$5B1C` | `C9` | `RET` | |
| `$5B1D` | `00 00 00` | | |

- The stub does not test the carry LD-BYTES returns: a tape error runs into the game anyway.
- **The second half is a save routine** for the same block, never reached from the first half (the `JP $6300` before
  it): the authors' mastering tool left in the block (doc 10).
- The game block starts with 576 bytes before the entry (`$60C0-$62FF`, zero but `$01` at `$60E3` and `$02` at `$60E8`), then
  `$6300` `JP $68F3`, then the game's variables from `$6303`.

**The point**: the whole loader is six instructions; the game needs no protection step and no setup from BASIC
beyond RAMTOP.
