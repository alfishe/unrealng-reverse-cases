# 3. Build and load

What this covers: the disk block by block, the boot, the Trush packer, the patch installer that turns Hewson's
Zynaps into the GS version, and what is uploaded to the General Sound card and when. The runs it rests on are listed
in `work/stage1/NOTES.md`. This is the stage 1 draft; the source build is not written yet.

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - an animation of every unpack (`kit/memanim.py`) -->
<!-- - the build (mermaid) -->
<!-- - the disk map (sectors by owner) -->

## 3.1 The medium

`orig/ZYNAP_GS.ZIP` (md5 `187e99851aad93ecd03c032e65f753aa`, SHA-1 `73c7880e5a262cfb9fd0883bfb00ebed07fc568e`)
holds `ZYNAP_GS.TRD`:

- 655360 bytes;
- md5 `133a8fe861f814b2d6d67e6539c81b85`, SHA-1 `bc0661fc8f384d76b4d5c321c151d156b538c52e`;
- disk label `AMD4ever`, 9 files, 370 sectors free.

| # | Name | Type | Start / length | Sectors | First sector | What it is |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | `ZYNAP_GS` | BASIC | 65 bytes | 255 | 1:0 | the loader line; the boot code is in its tail sectors |
| 1..7 | `zynapsGS` | `1`..`7` | start = length = n | 255 each | 16:15, 32:14, .. 112:9 | covers |
| 8 | `zynapsGS` | `8` | 8 / 8 | 134 | 128:8 | the last cover |

The covers hold no data of their own. They claim the data sectors so that nothing else is written over them.

Together, the nine entries claim 2174 sectors from track 1 sector 0, in one contiguous run. The game reads the run
with its own sector reader, by position, and never goes through the catalogue. Below, "blob sector n" means TRD
sector n + 16, so track 1 sector 0 is blob 0 (`work/images/disk/trd-from-track1.bin`).

`ZYNAP_GS` reads:

```
1 RANDOMIZE USR VAL "23882" : (code) : REM MIKE BLUM (C)1997
```

The BASIC lies at PROG `$5D3B`, where TR-DOS puts it. `USR 23882` enters `$5D4A`, which is machine code in the line
itself. That code does the following:

1. `DI` and `SP = $8000`.
2. Pushes `$5D3B` as the return address.
3. Clears four bytes.
4. Calls TR-DOS's `$3D13`, which reads 2 sectors from (`$5CF4`) (the next position) to `$5D3B`.

So the first two tail sectors land over the BASIC line, and the code returns into them.

## 3.2 The disk map

The tables behind this section are in `work/stage1/`:

- `disk-blocks.txt` gives the sectors;
- `trush-blocks.txt` lists the 38 packed blocks;
- `level-table.txt` holds the sound records.

| Blob sectors | Read to | Becomes | Contents |
| --- | --- | --- | --- |
| 0 | `$5D3B` (TR-DOS) | | the BASIC line |
| 1..2 | `$5D3B` | | the boot code (3.3) |
| 3..15 (13) | `$7E2C`, page `$17` | Trush blk00 → `$7F58-$9AFF` | the loading screen and the code that shows it (" PROGRAM BY MIKE BLUM ") |
| 16..55 (40) | `$D29F`, page `$11` | Trush blk01 → bank 1 `$D3CB-$FFFF` | the start jingle (an FX of 9946 bytes), in-game FX 1 and the start of FX 2 |
| 56..119 (64) | `$C000`, page `$13` | bank 3, raw | in-game FX 2 (rest) to 5 (start) |
| 120..177 (58) | `$BED4`, page `$14` | Trush blk02 → bank 4 `$C000-$FFFF` | in-game FX 5 (rest) to 8 (start) |
| 178..226 (49) | `$BED4`, page `$16` | Trush blk03 → bank 6 `$C000-$FFFF` | in-game FX 8 (rest) to 10 |
| 227..320 (94) | `$607C`, page `$10` | Trush blk04 → `$61A8-$FFFF` | the patch installer, the GS driver file, the level loader, and Hewson's Zynaps (3.5) |
| 321..2173 | the level loader, record by record | the card | the effects-only FX set (4 records) and 13 modules (45 records), see [9.3](09-sound.md#93-the-media) |

## 3.3 The boot

The boot code at `$5D3B` comes from blob sectors 1-2. It runs these steps:

1. Clears the screen.
2. Reads 13 sectors with page `$17` to `$7E2C` and runs them. This is a Trush block that unpacks the loading screen
   to `$7F58-$9AFF`. The block copies `$8000` → `$C000` (`$1B00` bytes, into bank 7) and calls `$7F58`.
3. Reads 40 sectors with page `$11` to `$D29F` and runs them. They unpack to bank 1 `$D3CB-$FFFF`.
4. Reads 64 sectors with page `$13` to `$C000`. Bank 3 is not packed.
5. Reads 58 sectors with page `$14` to `$BED4` and runs them. They unpack to bank 4 `$C000-$FFFF`.
6. Reads 49 sectors with page `$16` to `$BED4` and runs them. They unpack to bank 6.
7. Reads 94 sectors with page `$10` to `$607C` and runs them. They unpack to `$61A8-$FFFF`.
8. Fades the screen (`$5D9F`), calls `$6D60` and jumps to `$61A8`.

The sector reader is at `$5DDF`. It takes:

- B: the number of sectors;
- C: the `$7FFD` value;
- (`$5CF4`): the position, which is TR-DOS's next sector.

The reader normally reads through a ROM gadget of TR-DOS. If ENTER is held at boot, it uses TR-DOS's `$3D13` entry
instead.

The menu's "TURBO LOADER" option is probably the same switch for the level loads. Stage 2 is to confirm this.

## 3.4 The Trush packer

Every packed block carries "COMPRESSOR BY ALEXANDER TRUSH ODESSA". The blocks unpack themselves:

- `+$00` moves the packed stream up so that it ends at the destination's end, with SP on its first byte. The code is
  `DI; LD B,16; EXX; PUSH HL; LD HL,src_end; LD DE,dest_end; LD BC,packed_len; PUSH DE; LDDR; ...`.
- `+$22` copies the depacker (`$CE` bytes from `+$4B`) over the head through the ROM's `LDIR; RET` at `$33C3`.
- The depacker reads the stream through SP. Bytes and 16-bit bit words are interleaved. The next word is read as
  soon as the last bit of the previous one is taken, not when the next bit is needed.
- Tokens: `0` is a literal byte. `1` is followed by a length code and an offset.
  - The length codes are:
    - `00`: 3.
    - `010`: 2, with a 1-byte offset.
    - `011`: a length byte follows. `$FF` ends the stream, `$FE` means a 16-bit length follows, and any other n means
      n + 10.
    - `100`: 4.
    - `101`: 5.
    - `11xx`: 6..9.
  - The offset is either one byte, or a high part of 2 to 6 bits followed by a byte.
- The depacker writes upwards from `+$CE`. It then moves the output so that it ends at `dest_end`, and returns.

`tools/trush.py` unpacks all 38 blocks on the disk to their exact lengths (`work/media/unpacked/`). There is no
other packer on the disk. The signature base has no Trush entry (`work/stage1/sig-summary.txt`).

## 3.5 The patch installer

blk04 runs at `$61A8`. It carries Hewson's Zynaps at Zynaps's own addresses from `$7400` up, and the first 6 K of
Zynaps at `$C800`. The installer does these things:

- It copies the stubs:
  - `$AA28`: the effects timer and the title entry;
  - `$5B00`: code that the game reaches through the word patched at `$B20A` (stage 2 reads it);
  - `$B2F0` and `$A6AE`;
  - `$FF1C` (`$B6` bytes): 20 sound and level stubs;
  - `$B446` (`$62` bytes): the bank 1 trampolines `$B466` / `$B482` and the flags `$B45F..$B486`.
- It copies the GS driver file (`$64B3`, `$1000` bytes) to bank 1 `$C000`, and saves the area at `$5B00` to bank 1
  `$D190`.
- It writes the call sites into Zynaps: 25 places, each one a `call` / `jp` to a stub. The list is in
  [9.4](09-sound.md#94-where-the-game-makes-a-sound).
- It moves `$C800` → `$5C00` (`$1800` bytes) and jumps to `$B200`, where Zynaps starts.

These are the changes the GS version makes to Zynaps:

- The sound requests. Six sites called the beeper request `$B2F0` and now call stubs, and the seventh, at `$ABF1`,
  is removed outright.
- 13 new sound hooks, at places that made no sound before.
- The level and round hooks.
- The wait between rounds.

The diff of the patched area against the original bytes (both are in blk04) is 285 disassembly lines over
`$9400-$B4FF` (`work/tmp/orig-9400.dasm`, `work/tmp/live-9400.dasm`).

## 3.6 What goes to the card, and when

The GS ROM's own player does all the work. No program is uploaded to the card; only samples and modules go there,
through the firmware's load commands. These are the live traces (`work/stage1/x1/*-digest.txt`,
`work/stage1/x2/*-digest.txt`):

| Moment | Commands |
| --- | --- |
| boot to the menu | nothing |
| menu key 1 or 2 (the title) | `#23` (pages), `#F3` (warm reset), `#30` load module → handle 1, `#D1`, 51456 bytes (the title module, level 13), `#D2`, `#2A $40`, `#31 1` |
| game start (`$FF26`, before "PREPARE FOR COMBAT") | `#23`, `#F3`, `#38` load FX → 1, 9946 bytes (the jingle), `#2E 1` `#40 $33` `#81` |
| the round start (`$FF1C`) when the level changed | music: `#23`, `#F3`, the level's module, the 10 in-game FX, `#2B $40`, `#2A` (the level's volume), `#31 1`; effects only: the 10 FX and the 11 disk FX, `#2B $40` |
| play | `#2E` / `#40` / `#80+c`, or `#2E` / `#40` / `#45` / `#39` ([9.4](09-sound.md#94-where-the-game-makes-a-sound)) |

Every command waits for the card to take the previous one (`IN $BB` bit 0). Every stream byte waits for the data
latch (bit 7). Every trace had 0 unchecked writes, over about 400 K stream bytes in all. Nothing is lost the way
Nether Earth GS's 2002 loader lost its module.

## 3.7 The build

Not written yet (stage 2). The disk is to be rebuilt from source byte for byte. The packed blocks are to be repacked
by a Trush packer that gives the same bytes; if that is not possible, they stay as resources.
