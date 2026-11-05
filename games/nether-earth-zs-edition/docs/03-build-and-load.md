# 3. Build and load

Status: stage 1 draft. What is here is taken from the recordings' writes and runs and from the static unpacks that
match them; the source build does not exist yet.

This document covers how the two releases of Nether Earth ZS Edition get from their disks into memory: the BASIC,
the loaders, the '99 packer and its block format, what is unpacked where and in which page.

The recordings and runs it rests on (all PENTAGON 128 + TR-DOS 5.04T in unreal-ng, muted, own port bases):

- `r98`: power-on, TR-DOS from the Pentagon menu, `RUN "NEZSEd"`, the intro, SPACE, the menu, `0`, play
  (`work/stage1/r98`, script `inputs/r98.txt`, recording frames 103-5903; a recording frame is the script's + 1603);
- `r99`: the '99 disk autostarted (the quick reset into TR-DOS, recording from frame 2), the intro, SPACE, the
  start-up menu, every menu page, LOAD MAP, LEVEL HARD, UPGRADING PHASERS, START, play (`work/stage1/r99`, script
  `inputs/r99-128.txt`, frames 2-6462);
- `r99-48`: power-on, the Pentagon menu's "48 BASIC" (paging locked), `RANDOMIZE USR 15616`, `RUN "NEZSEd99"`: the
  path a 48 K machine would take (`work/stage1/r99-48`, frames 101-7201);
- `x99p`: the '99 disk started from the Pentagon menu's TR-DOS item: hangs in the intro (3.6).

The static side: `tools/scl.py` (SCL list and extract), `tools/zsdepack.py` (the '99 depacker reimplemented).

## 3.1 The media

| Release | Archive (md5) | SCL | Files |
| --- | --- | --- | --- |
| '98 | `orig/NEZSED98.zip` (`d5e0b181c5323a9bc5459399f4c4953f`) | `NEZSED98.SCL` | one: `NEZSEd.B`, 157 sectors |
| '99 | `orig/NEZSED.ZIP` (`24a13a6972ddfad4db560ec496799f2b`) | `NEZSED.SCL` | 18 (below) |

The '99 disk:

| File | Type, catalogue | Sectors | What |
| --- | --- | --- | --- |
| `NEZSEd99.B` | BASIC, 48 bytes | 133 | the BASIC (sector 0) and, read by number, every block (3.3) |
| `NEabout.W` | `W` 38912, 3763 bytes | 15 | the author's story of the edition (CP866) |
| `NEdescri.W` | `W`, 5469 bytes | 22 | the game description |
| `NEgreets.W` | `W`, 313 bytes | 2 | greetings |
| `NEadvice.W` | `W`, 5572 bytes | 22 | "Advices of Expert" by Timofey Anisimov |
| `NEZSEd99.W` | `W`, 5384 bytes | 22 | the readme (not read by the program) |
| `NELEV_00.N` .. `NELEV_11.N` | `N`, words 0 | 2 each | twelve maps, 512 bytes each (3.5) |

The `.W` texts are ZX Word documents (the intro scroller says so); content and translation: `work/stage1/texts.md`.

## 3.2 The '98 load

`NEZSEd.B` is a BASIC monoblock: 340 bytes of BASIC (2 sectors), then 42 sectors of the intro, then 113 sectors of
the game, read by sector number from the BASIC's own position.

| Step | Where | Evidence |
| --- | --- | --- |
| line 10 `CLEAR VAL "26495": RANDOMIZE USR VAL "23872"` | `$5D40`, the code in line 1's REM | `r98` stage 3: `$5D40` entered at frame 2000 from `$34BB` (`USR`) |
| copy ROM's font `$3D00` to `$C000` area, bold, `CHARS=$BF00`; print "ZS'98 Presents: NETHER EARTH ZS EDITION" | REM code | screen in `r98` |
| `#3D13` read `$2A` sectors to `$C000-$E9FF`, `CALL $D88F` | the intro (3.4) | stage 4: `$C000-$E9FF` written by `$3FEC` (TR-DOS), `$D88F` entered at frame 2048 |
| read `$71` sectors to `$6780-$D87F`, `JP $A600` | the game, at NE's own addresses, not packed | stage 9: `$A600` entered at frame 4500 from `$5D94` |

- The game image equals the file's bytes from offset `$2C00` placed at `$6780` (`work/static98-game.bin`): at the
  menu (`r98` frame 4600) 3 bytes differ, all game variables (`$C4D0`, `$C4D6`, `$C4EF`).
- The intro at `$C000` equals the file's `$200-$2BFF` (`work/intro98-C000.bin`) except 130 bytes the PT3 player's
  init writes at frame 2048 (its variables and note table, `$C048-$C0FF`).
- The BASIC's VARS area holds more code at `$5DEF` (`RES 4,(IY+1)`, pages `$51`/`$57`/`$54` to `$7FFD`): a 128 K
  loader left behind. Nothing in `$5D97-$5FFF` runs in `r98` (the executed blocks there end at `$5D96`).
- `$5B00-$5B2E` runs: TR-DOS's own paging stub on this machine, not the game's.

## 3.3 The '99 load

`NEZSEd99.B`: line 10 `CLEAR 24999: RANDOMIZE USR 23899`. The code at `$5D5B` (in the BASIC) reads 18 sectors to
`$8000` and returns into it. From then on every program is a self-extracting packed block (3.4) read by sector
number; sector numbers below count from the file's first sector.

| Sectors | Read to | Unpacks to | What | `r99` arrival |
| --- | --- | --- | --- | --- |
| 0 | `$5D3B` | | the BASIC, the first reader at `$5D5B` | `$5D5B` at 152 |
| 1-18 | `$8000` | `$61A8-$7D86` (far 11) | stage 2: the intro (3.4) | `$8000` at 177, `$61A8` at 227 |
| 19-31 | `$7D87` | | not packed: the RLE screen decoder and the pictures | `$7D87` at 464 |
| 32-44 | `$C000` | | not packed: Sound Tracker compiled module and player (init `$C00B`, mute `$C011`) | `$C00B` at 261 |
| 45-50 | `$8000` | `$61A8-$67EB` (far 10) | stage 3: "System checking", the memory test, the game load | after SPACE |
| 51-118 | `$6780` | `$6780-$D7D2` (far 11) | the game, at NE's addresses | `$6780` at 2299 |
| 119-122 | `$DC00` | `$D800-$DB6F` (far 10) | patches: `$D800` -> `$A598` (`$3E` bytes), `$D83E` -> `$C1FD` (`$136` bytes) | `$DC00` at 2545 |
| 123-132 | `$E800`, page 1 | `$D800-$E6F3`, page 1 (far 10) | the 128 K start-up menu (128 K only) | `$E800` at 2561 |
| `NEabout.W` .. 3 sectors of `NEZSEd99.W` (64) | page 3 `$C000` | | the four texts: `$C000` about, `$CF00` description, `$E500` greets, `$E700` advice | before 2659 |

Then stage 3 patches NE's menu pointers (`$C116`, `$C146`, `$C125`, `$C13B`, `$C130`) and:

- if `(IY+$77)` (`$5CB1`, the page count the memory test left) is 1: `JP $A600` (the 48 K path: the texts and maps
  are read from disk when asked);
- else pages 1 in by `$A58A`, loads the menu block, pages 3 in, reads the 64 text sectors, sets the pointers to
  the texts in page 3 and `JP $A600`; `$A600` reaches the start-up menu at `$D800` in page 1 (`r99` frame 2661).

Checks against the static unpacks (`tools/zsdepack.py block`):

- stage 2 at `r99` frame 262, `$61A8-$7D86`: 0 bytes differ;
- the game at frame 2554, `$6780-$D7D2` (page 0 at `$C000`): 0 bytes differ outside the areas the patches write
  after the unpack (`$A56A-$A5D5`, `$C100-$C17E`, `$C1FD-$C332`, frames 2553-2659);
- stage 3 at frame 2300: equal except `$663A-$66AD` (its page table and screen strings, written as it runs);
- the menu at frame 3700, `$D800-$E6F3`: equal except `$DE31-$DEF0` (the 192 attribute bytes it saves).
- Every block's stream is consumed exactly: the source pointer ends at the block's own start.

## 3.4 The '99 packer

A backward LZ with a bit stream read from the end; the depacker is `$9A` bytes, copied to `$5B00` by each block.

A block loaded at AT:

| Offset | Bytes | What |
| --- | --- | --- |
| `+$00` | `$16` | set-up: `LD DE,$5B00`, `LD HL,AT+$16`, `LD BC,$9A`, `LDIR`; then `DE = AT`, `HL = AT+$B0`, `BC` = packed length (word at `+$13`), `JP $5B00` |
| `+$16` | `$9A` | the depacker; its first `LDIR` moves the stream down to AT |
| `+$B0` | length | the packed stream |

Operands inside the depacker (offsets from `+$16`): `+$06` source end, `+$0B` destination end, `+$6C` far-offset
bits (11 or 10), `+$78` stop (the byte below the first output byte), `+$81` the jump when done (`$0052`, a `RET`
in the ROM, for the blocks called from stage 3; `$61A8` for the two loader stages).

The tokens (bits from bit 7 of each byte, bytes from the end down):

| Bits | Meaning |
| --- | --- |
| `0` + 8 | a literal byte |
| `11` + 1 | match of 2-3 |
| `101` + 2 | match of 4-7 |
| `1001` + 4 | match of 8-22; value 15: a literal run of 14 + 5 bits bytes |
| `1000` + bytes | match of 23 + the byte; a byte `$FF` adds the next one |
| offset `1` + far bits | `+$221` |
| offset `01` + 5 | `+1` |
| offset `00` + 9 | `+$21` |

The match is an `LDDR` from `DE + offset`. Sizes: stage 2 4424 -> 7135, stage 3 1268 -> 1604, game 17206 -> 28755,
patches 651 -> 880, menu 2223 -> 3828.

Identification: not identified. The depacker is byte-identical except for its addresses in other disks of the time
(ZX Format #7 disk 2 "R.R.demo", `CHASE_HQ.SCL`, `HAPPYNEW.$B`, `BRAIN_CR.$B`, `XAS9_10`, `SAA10991.TRD`,
`SG2.01m.scl`), and a variant with a 12-bit far offset is in `POOGABOO.$B` of Spectrum Expert #1, whose disk also
holds LCP 128 ("COMPRESSOR BY ALEXANDER TRUSH ODESSA"). That is a candidate attribution only; the packer is not in
`R/signatures` and is not added (`work/stage1/NOTES.md`).

## 3.5 The maps (`NELEV_xx.N`)

512 bytes each: NE's four 3-byte record lists (scenery west, scenery east, ending 0; bases west, east, ending `$FF`),
then at `$1F3` a tail: the base count (`$1C` = 28 in `NELEV_00`), four list pointers (`$BDA9`, ...), a word `$FDxx`,
a byte (the enemy's war bases?) and `$63`. LOAD MAP in the '99 menu shows the twelve names and loads the one chosen
(`r99` around frame 5550). The '98 menu's key 5 copies 500 bytes from `$DD00` (scroller text in the image) to
`$BDA9` without reading the disk: starting a game after it crashes (`work/stage1/NOTES.md`, the brief of the changes).

## 3.6 Machines and the ROM

- The '98 runs on a Pentagon 128 with TR-DOS; it pages only to set the intro's `$7FFD=$10`.
- The '99's stage 3 runs a memory test (`$647B`) that knows many paging schemes (`$7FFD`, `$1FFD`, `$DFFD`, `$FDFD`,
  `$7FF7`/`$FFF7` ...) and leaves the page count in `$5CB1` and a scheme bitmask in `$5CB0`. On Pentagon 128 it
  finds 5 (`$5CB0=$01`), prints "Memory 128Kb" (`(n + 3) * 16`).
- In `r99-48` (paging locked by "48 BASIC") the count is 0: "Memory 56Kb" (the formula's carry), then the 128 K
  branch, the menu and texts go into the one page at `$C000` over the game, and it ends in BASIC with `0 OK`
  (screens `work/stage1/screens/99-48lock-*.png`). Whether a real 48 K machine gets 1 is open; unreal-ng has no
  48 K + Beta Disk model to test it, and its 48K / 128K models have no usable TR-DOS here.
- Started from the Pentagon menu's TR-DOS item the '99 hangs in the intro (`x99p`): unreal-ng's patched 48 BASIC
  ROM (`data/rom/pentagon.rom`) calls `$3A42` from its ISR when FLAGS bit 4 is set and that writes `$5B88`, inside
  the depacker copy. The autostart (FLAGS `$C8`) and "48 BASIC" paths do not set it.
