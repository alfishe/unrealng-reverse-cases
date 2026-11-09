# 3. Build and load

What this covers: the medium block by block, the Hewson loader, the packed loading screen, the move of the game into
place, and the source build. It rests on the static decode of the tape (`tools/tzxblocks.py`,
`tools/basic_list.py`, `tools/xorchain.py`, `tools/picy.py`) and on one recording ([Terms](README.md#terms)):

- `c1`: power-on with `Exolon.tzx`, 48K, the load (12 700 frames), then 16 000 frames of seeded random play
  (`work/c1`, WALKTHROUGH 1). The emulator's fast load took the two ROM-loaded blocks (BASIC and loader) by frame
  250; the Hewson loader's blocks played at signal speed. Every frame number here is a `c1` frame.

`python3 tools/check_load.py --work work/c1` reads `c1`'s memory at each stage's entry and compares it with the
static decode (3.5).

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

**The type-42 headers as a protection.** The ROM's LOAD reads every header in LD-LOOK-H `$0767` and drops a type of
4 or more without a word (48K ROM, bytes `FE 04 30 D9` checked in `data/rom/48.rom` of unreal-ng):

```asm
0784  DD BE EF    CP (IX-17)        ; the type asked for against the type read
0787  20 02       JR NZ,$078B
0789  0E F6       LD C,$F6
078B  FE 04       CP 4              ; type 4 or more?
078D  30 D9       JR NC,$0767       ; yes: back to LD-LOOK-H, the next header, nothing printed
```

- A type-42 header is never printed ("Bytes: exolon" does not appear) and never taken.
- Its data block has flag `$FF`, and LD-LOOK-H asks for a header (flag 0), so the data is skipped too.
- So `LOAD "" CODE`, or any copier that loads through the ROM's LOAD, waits past both files and sees an empty tape.
  Only code that calls LD-BYTES itself, and does not check the type, can read them. The Hewson loader is such code.
- **The point**: two Hewson files are hidden from BASIC at the cost of one changed byte per header. This is known
  from the ROM's code; no recording loads the tape through the ROM's LOAD.

![Exolon.tzx: 13270 frames of signal; the picture done at 1825, the game at 12376 (c1)](img/load/tape.png)

How to read the figure:

- **The top bar** is the TZX played at ROM speed, in frames from the start of the tape (50 a second): each block a
  box (grey: headers; blue: the BASIC; orange: the loader; violet: picy; green: the game), the pauses dark between.
- **The middle bar** is what `c1` did with it: the two ROM files taken by the emulator's fast LD-BYTES trap (the
  loader entered at frame 250), the picy file until its unpacker runs at frame 1808, the code file until MoveStub
  at frame 12364, the move until the game's entry at frame 12376.
- **The five screens** are `c1`'s screen at the end of the frame the yellow dot marks (TTD `memory_at`):
  - frame 200: the ROM's own screen, while the fast load takes the BASIC and the loader;
  - frame 1818: black, though picy is writing the bitmap: the loader cleared the attributes to 0 (3.3, 3.4);
  - frame 1826: the attributes are written and the whole picture is there at once;
  - frame 12300: the same picture for 10 500 frames, the counter in the boxes at the bottom right;
  - frame 12500: the game's menu.
- **The point**: the two ROM files cost nothing in `c1`, the two Hewson files play at the signal's own speed. The
  player sees the picture after about 36 s and then waits about 3.5 minutes with only the counter moving.

```bash
python3 tools/fig_load_tape.py --work work/docs/docA/c1 --out docs/img/load/tape.png
```

`work/docs/docA/c1` is `c1` opened read-only on an own instance (`re_session.py open --work work/docs/docA/c1
--ttd work/c1/session.ttd --port-base 27000`); the traces below are kept in its `traces/`.

### 3.1.1 The TAP copy

`orig/Exolon.tap.zip` holds a modified copy, not the release. Its blocks 4-8 are those of the TZX except the
loader, which is stored already decrypted. `cmp work/media/tap-loader.bin work/media/loader1.bin` finds no
difference: it is the output of 3.3 byte for byte. The case keeps the TAP as found; the build targets the TZX.

Its BASIC, `python3 tools/basic_list.py work/media/tap-basic.bas` (two lines, 457 bytes):

```text
   10 BORDER 0: PAPER 0: INK 7: CLEAR 25999: LOAD "" CODE : POKE 64659,0: POKE 65105,195: POKE 65106,153:
      POKE 65107,252: FOR f=64662 TO 64689: READ a: POKE f,a: NEXT f: RANDOMIZE USR 65082
   20 DATA 195,98,5,243,205,142,2,28,40,250,62,33,50,81,254,62,95,50,82,254,62,254,50,83,254,195,81,254
```

Line by line:

- `CLEAR 25999` and `LOAD "" CODE` are those of the TZX (3.2). The loader arrives plain at `$FC00`.
- `POKE 64659,0`: `$FC93` is the operand of LdBytes' `LD A,$0A`, the border at the start of a block. It becomes
  black.
- `POKE 65105-65107` writes `C3 99 FC`, `JP $FC99`, over Start's `LD HL,MoveStub` at `$FE51`.
- The 28 DATA bytes go to `$FC96-$FCB1`, inside LdBytes:

```asm
FC96  C3 62 05      JP $0562          ; into the ROM's LD-BYTES, past its border set-up
FC99  F3            DI                ; Start's MoveStub step lands here
FC9A  CD 8E 02      CALL $028E        ; the ROM's KEY-SCAN
FC9D  1C            INC E             ; E = $FF: no key
FC9E  28 FA         JR Z,$FC9A        ; wait for a key
FCA0  3E 21 32 51 FE  LD A,$21 / LD ($FE51),A   ; put back LD HL,$FE5F
FCA5  3E 5F 32 52 FE  LD A,$5F / LD ($FE52),A
FCAA  3E FE 32 53 FE  LD A,$FE / LD ($FE53),A
FCAF  C3 51 FE      JP $FE51          ; MoveStub as on the TZX
```

- `RANDOMIZE USR 65082` enters at Start `$FE3A`, past the decryption.
- **The point**: the copy loads both type-42 files with the ROM's own bit loop. So a turbo or emulator TAP trap at
  `$0562` takes them, and there is no countdown. After the code file it waits for a key, with the picture shown,
  before the move. This is known only from the code: no recording loads the TAP.

## 3.2 The BASIC (TZX block 2)

`python3 tools/basic_list.py work/media/exolon.bas`:

```text
   10 BORDER 0: PAPER 0: INK 7: CLEAR 25999: LOAD "" CODE : RANDOMIZE USR 64512
   20 REM *************            (length word 98: runs 84 bytes past the program's end)
```

The header (block 1) says LINE 0 and a program length of 81 (`$0051`), with no variables. LINE 0 is below the
first line, so the ROM runs the program from line 10.

Line 10 byte by byte (`work/media/exolon.bas` offsets `$00-$3E`):

| Bytes | Meaning |
| --- | --- |
| `00 0A` / `3B 00` | line 10, its length 59 |
| `E7 30 0E 00 00 00 00 00 3A` | `BORDER`, `0`, the hidden number 0, `:` |
| `DA 30 0E 00 00 00 00 00 3A` | `PAPER 0:` |
| `D9 37 0E 00 00 07 00 00 3A` | `INK 7:` |
| `FD 32 35 39 39 39 0E 00 00 8F 65 00 3A` | `CLEAR 25999` (hidden `$658F`), `:` |
| `EF 22 22 AF 3A` | `LOAD "" CODE :` |
| `F9 C0 36 34 35 31 32 0E 00 00 00 FC 00 0D` | `RANDOMIZE USR 64512` (hidden `$FC00`), ENTER |

Each statement:

- **`BORDER 0: PAPER 0: INK 7`**: a black border and white on black. The ROM's "Bytes: exolon" message for the
  loader then shows white on black. The loader blacks out every attribute anyway (3.3).
- **`CLEAR 25999`**: RAMTOP goes to `$658F`, one below the code file's start `$6590`. The ROM moves the machine
  stack and the GO SUB stack below it. The loader keeps that stack (Start has no `LD SP`), so the code file can
  fill `$6590-$F82F` without hitting the stack it runs on. Zynaps' program is the same but for `CLEAR 32767`.
- **`LOAD "" CODE`** takes the next file, the loader, to `$FC00`, the address its header names.
- **`RANDOMIZE USR 64512`** enters the loader at `$FC00`. It never returns to BASIC.

**Line 20.** Its bytes are `00 14` (line 20), `62 00` (length 98), `EA` (`REM`) and 13 asterisks. Then the block
ends: there is no ENTER. The length word claims 98 bytes where 14 follow. What lies past the end is not on the tape.
In memory it is the ROM's own (`c1` `memory_at` of `$5D0A-$5DAF` at frame 250; PROG `$5CCB`, VARS `$5D1C`, E_LINE
`$5D1D`):

| Address | Bytes | What |
| --- | --- | --- |
| `$5D0A-$5D1B` | `00 14 62 00 EA 2A` x 13 | line 20 as loaded |
| `$5D1C` | `80` | the end of the (empty) variables area |
| `$5D1D-$5D21` | `EF 22 22 0D 80` | the edit line: the `LOAD ""` typed at power-on |
| `$5D22-$5D2C` | `03 FF 20` x 9 | the header LOAD "" CODE asks for (type 3, any name) |
| `$5D33-$5D43` | `03 65 78 6F 6C 6F 6E ... 00 03 00 FC 00 FC` | the loader's header as read |
| `$5D2D-$5D32`, `$5D44-$5D6F` | zeros | to the 98 bytes' end |

- So the 84 bytes past the end are no hidden code. They are the variables marker, the edit line and LOAD's two
  header buffers.
- Nothing reads line 20: the program never gets past line 10's `USR`. Only `LIST` would show it.
- The tape gives no reason for the 98. Most likely the line once held 96 asterisks and was cut to 13 for the
  release. Zynaps' tape has the same line 20.

## 3.3 The loader (TZX block 4)

The loader is 768 bytes at `$FC00-$FEFF`. Its first 19 bytes are plain. They decrypt the rest with one forward
XOR chain: each byte is XORed with the next byte as the tape holds it. The chain is 656 bytes long
(`LD BC,$0290`), `$FC13-$FEA2`. `tools/xorchain.py` writes the plain loader; its first instruction at `$FC13` is
`JP $FE3A`. After the chain the loader reads two hidden files with its own copy of LD-BYTES and shows a countdown
while they load.

It is the loader of Hewson's Zynaps, "Countdown II" (Zynaps
[3.3](../../zynaps/docs/03-build-and-load.md#33-the-loader-tzx-block-4-an-xor-chain-over-itself)); Zynaps' chain
was 652 bytes. The differences are listed below.

The plain head, as `src/tape/loader.asm` has it (`DecryptEnd` is `$FEA3`, the first plain byte after the chain):

```asm
Decrypt:
  LD BC,DecryptEnd-DecryptFrom  ; 656 bytes
  LD HL,DecryptFrom
  LD DE,DecryptFrom+1
DecryptLoop:
  LD A,(DE)                     ; the next byte, still as the tape holds it
  XOR (HL)
  LD (HL),A
  INC HL
  INC DE
  DEC BC
  LD A,B
  OR C
  JR NZ,DecryptLoop
DecryptFrom:
  JP Start
```

```text
for a = $FC13 to $FEA2:
    memory[a] = memory[a] XOR memory[a + 1]     ; memory[a + 1] is still the tape's byte
```

The key of each byte is the next byte as the tape holds it, so the chain needs no key of its own.

```mermaid
flowchart TD
  A["Decrypt $FC00: BC = $0290 (656), HL = $FC13, DE = $FC14"] --> B["A = the byte at DE, still as the tape holds it"]
  B --> C["A = A XOR the byte at HL"]
  C --> D["the byte at HL = A: one byte plain"]
  D --> E["HL + 1, DE + 1, BC - 1"]
  E --> F{"BC = 0?"}
  F -- "no" --> B
  F -- "yes: HL = $FEA3" --> G["run on into $FC13: JP Start $FE3A"]
```

A worked step, the first three bytes and the last, from the tape's block 4 (`work/media/loader.bin`):

| Step | Before: HL, DE, BC | A = (DE) | XOR (HL) | Stored at HL | After: HL, DE, BC |
| --- | --- | --- | --- | --- | --- |
| 1 | `$FC13`, `$FC14`, `$0290` | `$B4` | `$77` | `$C3` (`JP`) | `$FC14`, `$FC15`, `$028F` |
| 2 | `$FC14`, `$FC15`, `$028F` | `$8E` | `$B4` | `$3A` | `$FC15`, `$FC16`, `$028E` |
| 3 | `$FC15`, `$FC16`, `$028E` | `$70` | `$8E` | `$FE`: `JP $FE3A` | `$FC16`, `$FC17`, `$028D` |
| 656 | `$FEA2`, `$FEA3`, `$0001` | `$00` (plain) | `$C9` | `$C9` (`RET`) | `$FEA3`, `$FEA4`, `$0000`: the loop ends |

Each step reads the key at DE before the step at DE writes it: DE runs one byte ahead of HL, so the key is always
the tape's byte. The loop is nine instructions, 59 T-states a round, so 656 rounds take 38 699 T; `c1` measures
39 570 T. Interrupts are still on (the `DI` comes at Start), so the rest is most likely the ROM's frame interrupt at
the start of frame 251.

The first and the last bytes (`work/media/loader.bin`, the tape's block 4, and `loader1.bin`, the decrypted loader):

| Address | Tape byte | XOR the next tape byte | Plain byte | What |
| --- | --- | --- | --- | --- |
| `$FC13` | `$77` | `$B4` | `$C3` | `JP` |
| `$FC14` | `$B4` | `$8E` | `$3A` | low byte of `$FE3A` |
| `$FC15` | `$8E` | `$70` | `$FE` | high byte: `JP $FE3A`, Start |
| `$FC16` | `$70` | `$38` | `$48` | CountDigits, the first digit (9 x 8) |
| `$FEA2` | `$C9` | `$00` (`$FEA3`, plain) | `$C9` | `RET`, the last byte of `LoadFile` |

**The other direction.** The build turns the plain loader back into the tape's bytes
(`python3 tools/xorchain.py encrypt build/loader-plain.bin build/loader.bin`):

```text
for a = $FEA2 down to $FC13:
    tape[a] = plain[a] XOR tape[a + 1]          ; tape[$FEA3] = plain[$FEA3], outside the chain
```

- Each tape byte needs the tape byte after it. So the encryption must run from the top down, the opposite order of
  Decrypt.
- Run upward, it would XOR with a plain byte, and Decrypt would not undo it.

A worked example, the last four bytes of the chain:

| Address | Plain | XOR the next tape byte | Tape byte |
| --- | --- | --- | --- |
| `$FEA3` | `$00` | (outside the chain) | `$00` |
| `$FEA2` | `$C9` | `$00` | `$C9` |
| `$FEA1` | `$CF` | `$C9` | `$06` |
| `$FEA0` | `$30` | `$06` | `$36` |
| `$FE9F` | `$FC` | `$36` | `$CA` |

These are the bytes of `work/media/loader.bin`, the tape's block 4. `tools/build.sh` checks the whole result: the
built TZX is identical to the original (3.6).

![Decrypt: each byte XORed with the next, from FC13 up to FEA2 hex; the loader appears byte by byte](img/load/decrypt.gif)

How to read the animation:

- **The grid** is the loader's 768 bytes `$FC00-$FEFF`, 32 a row, each cell with its value at that moment of `c1`.
- **The colours**:
  - grey: plain on the tape (Decrypt itself and the tail `$FEA3-$FEFF`);
  - red: still as the tape holds it;
  - green: decrypted;
  - yellow: decrypted in this step of the animation; the white box is the byte HL points at.
- **The subtitle** gives the frame, the T-state, the count of decrypted bytes and HL.
- **The last picture** names the parts of the decrypted loader (white bars at the starts) with their ranges.
- **What it shows**: the green front moves forward one byte at a time. A byte becomes code or data only when the
  chain has passed it: `JP Start` at `$FC13`, the digit glyphs at `$FC32` (the regular `C6 FE FE ...` rows), the
  moved LD-BYTES.
- **The numbers**: the chain runs from frame 250 T 34 709 to frame 251 T 4 391, about 39 600 T-states; 653 of the
  656 bytes change (three bytes meet a zero as their key).
- **The point**: the protection is one forward pass of XOR with the next byte. A disassembler sees noise until the
  chain has run; the emulator sees it run in a little over half a frame.

```bash
python3 tools/fig_loader.py decrypt --work work/docs/docA/c1 --window 250:34000-251:6000 \
    --out docs/img/load/decrypt.gif
```

Against Zynaps' decrypted loader, 105 of the 768 bytes differ:

- the countdown's screen addresses: the four digits at `$50FB-$50FE` (row 23, columns 27-30) and their attribute
  cells `$5AFB-$5AFE`, where Zynaps' were at columns 1-4: the counter is drawn into the strip of boxes at the
  bottom right of the loading screen;
- the stages at `$FE3A` (below), three bytes shorter (no `LD SP`), and `LoadFile` seven bytes longer (the type
  check below): the chain is four bytes longer, 656 bytes against 652;
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
bytes of the code file as loaded) at the game's entry; Start then builds its tables over `$6590-$687F`, so only
`$6880-$6D5F` stays. `tools/image.py` writes the image as the move leaves it, `$6D60-$FFFF`. Why the code file
loads low and moves: 3.3.3.

The decrypted loader, part by part (`src/tape/loader.asm`):

| Address | Name | What |
| --- | --- | --- |
| `$FC00` | `Decrypt` | the XOR chain above, plain on the tape |
| `$FC13` | | `JP Start` |
| `$FC16-$FC19` | `CountDigits` | the four counter digits, units first, each 8 x the digit + a sub-step 0-7 |
| `$FC1A` | `CountOn` | 0 while a header loads, 1 while a data block loads |
| `$FC1B` / `$FC1D` / `$FC1F` | `CountGlyph`, `CountScreen`, `CountTick` | the digit being drawn, its screen address, the edges until the next move |
| `$FC21-$FC31` | `Header` | the 17 header bytes: type, name, length (`$FC2C`), start (`$FC2E`), a second parameter |
| `$FC32-$FC89` | `DigitGlyphs` | 11 glyphs of 8 lines, 0-9 and 0 again, inverted |
| `$FC8A` | `LdBytes` | the ROM's LD-BYTES (`$0556`), moved |
| `$FD1C` / `$FD20` / `$FD23` | `LdEdge2` / `LdEdge1` / `LdSample` | the ROM's LD-EDGE-2, LD-EDGE-1 and its sampling loop; `LdEdge1` jumps to `CountStep` first |
| `$FD3B` | `CountStep` | the countdown's work in the time of the ROM's delay loop (3.3.2) |
| `$FDA2` | `CountAdvance` | the odometer one sub-step down |
| `$FE0F` | `CountSet` | the start value: the header's length / 32 in four decimal digits |
| `$FE3A` | `Start` | the stages (above and 3.5) |
| `$FE5F` | `MoveStub` | 18 bytes copied to `$5B00` and run there |
| `$FE71` | `LoadFile` | a header of type 42, then its data block (3.3.1) |
| `$FEA3-$FEFF` | | plain, never run: 50 zeros, 20 bytes of leftover RAM, 23 bytes equal to the ROM's `$0652-$0668` |

### 3.3.1 LoadFile

Start calls LoadFile twice, once for each file. LoadFile loads a 17-byte header into `Header`, keeps it only if its
type byte is 42 (`$2A`), and then loads the data block that follows at the header's start address and length:

```asm
LoadFile:                       ; $FE71
  XOR A
  LD (CountOn),A                ; no counter while the header loads
  LD IX,Header                  ; $FC21
  LD DE,17
  XOR A                         ; flag 0: a header
  SCF                           ; carry: load, not verify
  CALL LdBytes
  JR NC,LoadFile                ; a bad block: start again
  LD A,(Header)
  CP FileType                   ; 42
  JR NZ,LoadFile                ; another type: wait for the next header
  CALL CountSet                 ; the counter from the length
  LD A,1
  LD (CountOn),A
  LD IX,(HeaderStart)           ; $FC2E
  LD DE,(HeaderLength)          ; $FC2C
  LD A,$FF                      ; flag $FF: data
  SCF
  CALL LdBytes
  JR NC,LoadFile                ; a bad block: start again with a header
  RET                           ; $FEA2
```

**The error path.** A bad block clears carry in LdBytes: a broken signal, a wrong flag byte or a checksum other
than 0. LoadFile then starts again from the header (`JR NC` at `$FE81` and `$FEA0`):

- CountOn goes back to 0, so the counter stops where it was and is drawn no more.
- The loader waits for the next header of type 42 on the tape. If the tape is rewound, that is the same file again
  and the load goes on.
- If the tape plays on after an error in the picture's data, the next type-42 header is the code file's. The first
  LoadFile then returns with the code file at `$6590-$F82F`, and Start's `CALL $8001` runs the code file's bytes
  there instead of the unpacker. The load does not recover.
- There is no message and no BREAK test: the ROM's SA/LD-RET is not pushed. The player has to rewind the tape.

This is known only from the code: every recording loads cleanly, and no run with a damaged block was made.

```mermaid
flowchart TD
  A["LoadFile $FE71: CountOn = 0"] --> B["LdBytes: 17 bytes, flag 0, into Header $FC21"]
  B --> C{"carry set: loaded, checksum good?"}
  C -- "no" --> A
  C -- "yes" --> D{"the type byte = 42?"}
  D -- "no: another file" --> A
  D -- "yes" --> E["CountSet: length / 32 into CountDigits; CountOn = 1"]
  E --> F["LdBytes: flag $FF, IX = the header's start, DE = its length"]
  F --> G{"carry set?"}
  G -- "no" --> A
  G -- "yes" --> H["RET to Start"]
```

The two headers in `c1` (`memory_at` of `Header` at frames 600 and 2100), both named `exolon`:

| File | Type | Length | Start | Parameter 2 |
| --- | --- | --- | --- | --- |
| the packed screen | 42 | 4096 (`$1000`) | `$8000` | `$4000` |
| the code | 42 | 37 536 (`$92A0`) | `$6590` | `$6784` |

LdBytes is the ROM's LD-BYTES (`$0556-$05E2`) in its structure: the leader (a wait of `$0415` rounds,
then 256 pilot pulses), the two sync edges, the flag byte compared with A, the bytes loaded or verified with the XOR
checksum in H, carry set on return when the checksum is 0. What differs:

- **No return address is pushed**: the ROM pushes SA/LD-RET (`$053F`), which restores the border and tests BREAK.
  LdBytes simply returns, carry clear on any error, and LoadFile starts again.
- **The border**: `$0A` once at the start (`$FC92`); then every edge writes `$08` (`LD A,0 / LD A,$08` at `$FD33`,
  the same length as the ROM's `AND 7 / OR 8`), black. The ROM's red and cyan stripes (`OR 2` at `$FC9B` is
  `OR 0`, the `XOR 3` after the sync is gone) never appear.
- **The counter switch**: C' is cleared at the start (`$FC8F`) and set from CountOn after the sync (`$FCD3-$FCDB`),
  which also sets CountTick so that the counter moves on the first edge of the block.
- **The edge routine**: `LdEdge1` (`$FD20`) is `JP CountStep` where the ROM has its delay loop (`LD A,$16` ...
  `AND A`, 358 T). CountStep does the counter's work and jumps to LdSample (`$FD23`), the ROM's LD-SAMPLE.
- **The type check** (`$FE83-$FE89`): the ROM's LOAD compares the header with the name asked for; LoadFile takes the
  first header of type 42, whatever its name. The ROM's own files (types 0-3) are passed over: their data block
  follows as a block with flag `$FF` that LoadFile, waiting for a header (flag 0), refuses at the flag test.

The time of the hooked edge, counted from the listing with the Z80's T-states (the loader sits above `$8000`, no
contention):

| Path through CountStep | T-states before LdSample | The ROM's LD-EDGE-1 |
| --- | ---: | ---: |
| a header (C' = 0): `CountIdle`, `DJNZ` 23 times | 368 | 358 |
| the colours (`CountAttrs`, then `DJNZ` 13 times) | 368 | 358 |
| a digit drawn (8 lines) | 357 | 358 |
| the odometer moved (`CountAdvance`, no borrow) | 369 | 358 |

LdSample's loop is 59 T a round, and a bit is the count of rounds over two edges against a threshold (`LD B,$B0`
and `CP B` with `$CB` at `$FD07`, the ROM's). The 10 or 11 T of difference is a fifth of one round: the loader reads
a standard ROM-timed tape, and `c1` loads it at signal speed.

### 3.3.2 The countdown

While a data block loads, four digits at `$50FB-$50FE` (row 23, columns 27-30, the top line of the cells; the
glyph's 8 lines go down by `INC H`) show the blocks of 32 bytes still to come, and run down to zero as the block
arrives.

CountSet (`$FE0F`) starts them from the header: the length shifted right five times (/ 32), then four digits by
repeated subtraction of 1000 (the rest x 10 each time), stored as 8 x the digit, thousands at `$FC19` first. The
packed screen starts at 4096 / 32 = 128, the code at 37 536 / 32 = 1173.

Each digit byte is 8 x the digit + a sub-step: the glyph is drawn from `DigitGlyphs + byte`, eight lines from
there. A sub-step of 0 is the digit's own glyph; 1-7 start 1-7 lines lower, so the cell shows the bottom of this
glyph and the top of the next one up. Counting down from 7 to 0 the glyph slides from the digit + 1 to the digit:
the digits roll like an odometer. The eleventh glyph (`$FC82`, a 0 again) is the one 9 rolls from.

```text
CountStep (every edge, in place of the ROM's delay):
    if C' = 0: wait 368 T; sample                  ; a header: no counter
    CountTick -= 1
    if CountTick = 0: CountAdvance                 ; every 64 edges
    elif CountTick < 5:                            ; ticks 4, 3, 2, 1
        draw the next digit to the left: 8 bytes of DigitGlyphs[CountDigits[i]] down the cell at CountScreen - 1
    else:
        the four attributes $5AFB-$5AFE = $47       ; bright white ink, black paper
    sample

CountAdvance:
    units -= 1; if units < 0: units = 79 (9, sub-step 7); tens -= 1     ; a borrow
    else: for tens, hundreds, thousands in turn:
        if the digit is mid-roll (byte AND 7 <> 0): byte -= 1
        if it went below 0: byte = 79 and the next digit - 1, and the move ends
    restart the drawing at the units ($50FE); CountTick = 64
```

```mermaid
flowchart TD
  A["LdEdge1: JP CountStep"] --> B{"C' = 0: a header?"}
  B -- "yes" --> I["a delay loop: 368 T in all"]
  B -- "no" --> C["CountTick - 1"]
  C --> D{"CountTick"}
  D -- "0" --> E["CountAdvance: the units one sub-step down, a borrow rolls the next digit; CountTick = 64"]
  D -- "1 to 4" --> F["one digit drawn, 8 lines, right to left from $50FE"]
  D -- "5 to 63" --> G["the cells $5AFB-$5AFE bright white"]
  E --> S["LdSample $FD23: the ROM's sampling loop"]
  F --> S
  G --> S
  I --> S
```

So one move comes every 64 edges: 32 bits, 4 bytes. Eight moves make one unit, 32 bytes. The counter runs only
inside the bit loop and takes no time of its own.

In `c1` (`memory_at` of `$FC16-$FC31`):

| Frame | CountDigits (units first) | CountOn | The counter | What |
| --- | --- | --- | --- | --- |
| 400 | `48 48 48 48` | 0 | 9999 (the image's) | the first header loading |
| 515 | | 1 | 0128 (CountSet) | the screen's header taken; its data block's leader |
| 665 | | 1 | | the first move (the data's sync) |
| 1000 | `46 40 00 00` | 1 | 0088 (units mid-roll) | the screen loading |
| 1800 | `0A 00 00 00` | 1 | 0001 | |
| 1830 | `4F FF 00 00` | 0 | | one move past zero: the units wrapped to 9, the tens to `$FF` |
| 2081 | | 1 | 1173 | the code's header taken |
| 6000 | `19 20 38 00` | 1 | 0743 | |
| 12363 | `00 00 00 00` | 1 | 0000 | the last bytes of the code |

The data block's first edge moves the counter at once (CountTick set to 1 after the sync), so a block of n bytes
makes n / 4 + 1 moves: one more than the counter holds, which is why the state at frame 1830 is one past zero. At
frame 1000 the four cells hold `$47` and the top line of each glyph, `$FE` (`memory_at` of `$5AFB` and `$50FB`).
The rate: 1173 units over frames 2081-12364, about 8.8 frames for 32 bytes.

The glyphs, inverted (a set bit is white paper, so the digit shows dark on a bright white cell):

```text
0 FE C6 BA BA BA BA C6 FE     5 FE 82 BE 86 FA BA C6 FE
1 FE EE CE EE EE EE 82 FE     6 FE E6 DE 86 BA BA C6 FE
2 FE C6 BA F6 EE DE 82 FE     7 FE 82 FA F6 F6 EE EE FE
3 FE 82 F6 E6 FA BA C6 FE     8 FE C6 BA C6 BA BA C6 FE
4 FE F6 E6 D6 B6 82 F6 FE     9 FE C6 BA BA C2 FA C6 FE
```

### 3.3.3 MoveStub: why the game is loaded low and moved

The game's image is `$6D60-$FFFF`, 37 536 bytes up to the top of memory. That range covers the loader itself,
`$FC00-$FEFF`. LdBytes runs at `$FC8A-$FD3A` while the file loads, so the file cannot load in place: the last
bytes would overwrite the code that loads them.

So the code file's header names `$6590`, `$7D0` (2000) bytes lower:

- The file then lies at `$6590-$F82F` and ends below `$FC00`.
- The loader survives the load and can move the file up afterwards.
- `$6590` is the lowest choice that keeps the stack safe: the BASIC's `CLEAR 25999` puts RAMTOP at `$658F`
  (3.2).

The move has two constraints:

- **The direction.** The target `$6D60-$FFFF` lies above the source `$6590-$F82F` and overlaps it. A copy from the
  bottom up would overwrite source bytes before they are read. `LDDR` copies from the top down: each target byte
  is written only after the source byte at the same address has been copied.
- **The place of the copying code.** The move overwrites `$6D60-$FFFF`, the loader included. So the code that moves
  must lie outside both ranges. Start copies the 18 bytes of MoveStub to `$5B00`, the 48K printer buffer, and jumps
  there.

Start's last step and MoveStub (`build/loader.lst`):

```asm
FE51  21 5F FE      LD HL,MoveStub                ; $FE5F
FE54  11 00 5B      LD DE,StubAt                  ; $5B00
FE57  01 12 00      LD BC,MoveStubEnd-MoveStub    ; 18
FE5A  ED B0         LDIR
FE5C  C3 00 5B      JP StubAt
MoveStub:                                         ; run at $5B00-$5B11
FE5F  21 2F F8      LD HL,GameLoaded+GameLength-1 ; $F82F, the file's last byte
FE62  11 FF FF      LD DE,GameLoaded+GameLength-1+MoveBy  ; $FFFF
FE65  01 A0 92      LD BC,GameLength              ; 37 536
FE68  ED B8         LDDR                          ; at $5B09
FE6A  31 5E 6D      LD SP,GameStack               ; $6D5E, below the game
FE6D  FB            EI
FE6E  C3 60 6D      JP GameEntry                  ; $6D60, Start
```

```text
StubAt[0..17] = MoveStub[0..17]
for i = 0 to 37 535:                    ; from the top down
    memory[$FFFF - i] = memory[$F82F - i]
SP = $6D5E; interrupts on; jump to $6D60
```

```mermaid
flowchart LR
  subgraph B["before the move, frame 12364"]
    B1["$5B00-$5B11: MoveStub, copied from $FE5F"]
    B2["$6590-$F82F: the code file as loaded"]
    B3["$F830-$FBFF: free"]
    B4["$FC00-$FEFF: the loader"]
  end
  subgraph A["after the move, frame 12376"]
    A1["$5B00-$5B11: MoveStub, left there"]
    A2["$6590-$6D5F: the file's first 2000 bytes, left over; the stack below $6D5E"]
    A3["$6D60-$FFFF: the game, the loader overwritten"]
  end
  B1 -- "runs the LDDR" --> A3
  B2 -- "LDDR: $F82F to $FFFF first, $6590 to $6D60 last" --> A3
```

A worked example, the first and the last byte the `LDDR` moves:

| Step | HL (source) | DE (target) | BC after | What |
| --- | --- | --- | --- | --- |
| 1 | `$F82F` | `$FFFF` | `$929F` | the image's last byte to the top of memory |
| 37 536 | `$6590` | `$6D60` | `$0000` | the file's first byte to Start's address: the loop ends |

- Both pairs differ by `$7D0`, the distance of the move.
- The first 2000 writes land on `$F830-$FFFF`, above the source: free memory and the loader. Every later write
  lands on a source byte that the copy has already read.
- **The time.** `LDDR` is 21 T a byte, so 37 536 x 21 = 788 256 T without contention. `c1` measures 12364 T 38 072 to
  12376 T 62 848, 863 432 T, 75 176 T more. The stub runs at `$5B00` and its opcode fetches at `$5B09-$5B0A` are in
  contended memory, as are the bytes below `$8000`. So the ULA delays the move while the beam draws the screen.
- **The interrupt window.** `EI` is followed by `JP $6D60` and the game's `DI`: 14 T with interrupts on. No
  interrupt falls in it in `c1` ([4.3](04-game-loop.md#every-di--ei-window-from-power-on)).
- **The point**: the move costs 12 frames, a quarter of a second, and the 18-byte stub is all the loader needs to
  hand the whole of memory above `$6D60` to the game.

## 3.4 The loading screen (TZX block 6)

The 4096 bytes at `$8000` are a packed screen together with its unpacker, `picy`. The block starts with a zero
byte and a `JR` over a small header: three stream offsets and the border colour. The unpacker follows.
`tools/picy.py unpack` gives the 6912 bytes of the screen (literals up to `$8BC0`, masks up to `$8F0C`, flags up to
`$8F78`, border 0). The format is below.

The packer marks a byte as a repeat whenever it equals the byte before it. `python3 tools/picy.py check` packs the
unpacked screen again and gets the tape's three streams exactly (2850 literals, 844 masks, 108 flags).

The block is the one of Hewson's Zynaps (Zynaps
[3.4](../../zynaps/docs/03-build-and-load.md#34-the-loading-screen-tzx-block-6-picy)), with only the padding changed.
`src/tape/picy.asm` assembles to the tape's block (3.6). The streams are shorter than Zynaps', so 136 zero bytes fill
the block's end where Zynaps' had 6.

The block (`src/tape/picy.asm`):

| Address | Bytes | What |
| --- | --- | --- |
| `$8000` | `00` | a zero byte before the entry |
| `$8001` | `18 08` | `JR Unpack`: Start calls here |
| `$8003` | `00` | unused |
| `$8004` | `$009D` | the literals' offset from `$8001`: `$809E-$8BBF`, 2850 bytes (read as `IX+3`) |
| `$8006` | `$0BBF` | the masks: `$8BC0-$8F0B`, 844 bytes (`IX+5`) |
| `$8008` | `$0F0B` | the flags: `$8F0C-$8F77`, 108 bytes (`IX+7`) |
| `$800A` | `$00` | the border colour (`IX+9`) |
| `$800B` | | the unpacker, 147 bytes to `$809D` |
| `$8F78` | 136 x `00` | to the block's 4096 bytes |

**Where am I.** The unpacker reads its header through IX, so it must know its own address. It does not assume
`$8001`. It finds the address at run time with two bytes written into the screen (`build/picy.lst`):

```asm
8014  21 E1 E9      LD HL,$E9E1        ; the bytes E1 E9: POP HL, JP (HL)
8017  22 00 40      LD ($4000),HL      ; written to the screen's first two bytes
801A  CD 00 40      CALL $4000         ; pushes $801D, the address after the CALL
WhereAmI:
801D  11 E4 FF      LD DE,-28          ; PicyEntry - WhereAmI
8020  19            ADD HL,DE          ; HL = $801D - 28 = $8001
8021  E5            PUSH HL
8022  DD E1         POP IX             ; IX: the header
```

```text
memory[$4000..$4001] = POP HL, JP (HL)
call $4000          ; the probe pops the return address into HL and jumps back to it
IX = HL - 28        ; the block's entry, wherever the block was loaded
```

- **The worked value**: the `CALL` at `$801A` pushes `$801D`. The probe pops it, so HL = `$801D`. Then `$801D` - 28
  (`$FFE4`) = `$8001`, the entry and the header's base.
- The stream offsets at `IX+3`, `IX+5` and `IX+7` are added to this base, so the block works at any address.
- The screen clear right after it (`LDIR` of 6912 zeros from `$4000`) wipes the two bytes.
- **The witness**: `c1` runs code at `$4000` at frame 1808 T 61 434, 133 T after the entry at T 61 301 (3.5,
  stage 3, written by `$8017`, entered from `$801A`).
- **The point**: the same packed block can be loaded anywhere. The screen is a safe place for the probe, because it
  is cleared at once anyway.

**The format.** The output is the 6912 screen bytes in address order from `$4000`: the bitmap in the Spectrum's
screen order, then the attributes. The flag stream has one byte for each 64 output bytes (108 x 64 = 6912), one
bit for each 8 of them, the lowest bit first: a set bit takes the next mask byte from the mask stream, a clear bit
stands for a mask of 0. The mask has one bit for each output byte, again the lowest first: set repeats the last
output byte, clear takes the next byte of the literal stream. The very first byte is always a literal (the carry
kept in F' is set before the first byte and cleared after it).

```text
IX = $4000; IY = literals; HL = masks; DE = flags; first = true
repeat 108 times:                          ; B = 108 groups
    for flag bit C = 1, 2, 4 ... 128:
        mask = (flags[DE] AND C) ? next byte at HL : 0
        for mask bit B' = 1, 2, 4 ... 128:
            if first or (mask AND B') = 0: (IX) = (IY); IY += 1       ; a literal, $8073
            else:                          (IX) = (IX - 1)             ; a repeat, $8081
            IX += 1; first = false
    DE += 1
```

```mermaid
flowchart TD
  A["the next flag byte at DE"] --> B{"its next bit set?"}
  B -- "yes" --> C["mask = the next byte at HL"]
  B -- "no" --> D["mask = 0"]
  C --> E{"the first byte, or the mask's next bit clear?"}
  D --> E
  E -- "yes" --> F["a literal: the byte at IY to IX; IY + 1"]
  E -- "no" --> G["a repeat: the byte at IX - 1 to IX"]
  F --> H["IX + 1"]
  G --> H
  H --> I{"8 mask bits done?"}
  I -- "no" --> E
  I -- "yes" --> J{"8 flag bits done?"}
  J -- "no" --> B
  J -- "yes" --> K{"108 flag bytes done?"}
  K -- "no: DE + 1" --> A
  K -- "yes" --> L["EI, RET to Start"]
```

A worked example, the first 24 output bytes, from the tape's streams: the flags begin `FF FB`, the masks
`C8 FF F1`, the literals `00 76 00 08 00 03 B0 00`.

| Output | Flag bit | Mask | Mask bits, lowest first | Bytes written |
| --- | --- | --- | --- | --- |
| `$4000-$4007` | flag 0 bit 0: set | `$C8` | 0 0 0 1 0 0 1 1 | `00 76 00` literals, `00` repeat, `08 00` literals, `00 00` repeats |
| `$4008-$400F` | bit 1: set | `$FF` | 1 1 1 1 1 1 1 1 | eight repeats of `00` |
| `$4010-$4017` | bit 2: set | `$F1` | 1 0 0 0 1 1 1 1 | `00` repeat, `03 B0 00` literals, four repeats of `00` |

The result, `00 76 00 00 08 00 00 00 / 00 x 8 / 00 03 B0 00 00 00 00 00`, is the start of
`src/res/screens/loading.scr` byte for byte: the start of the screen's top pixel line.

The screen: the EXOLON logo in yellow among dithered planets on black, HEWSON at the bottom left, a strip of boxes
at the bottom right that the countdown fills.

![picy: 6912 bytes in screen order; the picture shows only when the attributes come last](img/load/picy-unpack.gif)

How to read the animation:

- **Left, "what the TV shows"**: the screen as the TV draws it at that moment. It stays black: Start cleared the
  attributes to 0, black ink on black paper.
- **Right, "the bitmap as written"**: the same bytes drawn white on dark, so the bitmap can be seen. It fills in the
  Spectrum's screen order: line 0 of every character row of the first third, then line 1, and so on. New bytes are
  coloured: yellow a literal from the stream, cyan a repeat of the byte before.
- **The four bars** count the output bytes and how much of each stream is used: literals (`$809E`, IY), masks
  (`$8BC0`, HL), flags (`$8F0C`, DE); their totals are the tape's 2850, 844 and 108.
- **The last pictures**: the attributes `$5800-$5AFF` arrive and the picture appears on the TV at once.
- **The numbers**: the unpacker runs from frame 1808 T 61 301 to its `RET` at frame 1825 T 12 550, about 16.3
  frames; 2850 bytes come from the literal stream, the other 4062 are repeats.
- **The point**: the screen is unpacked hidden and shown in one stroke, in its last 768 bytes. Exolon's picture
  has large flat areas (the black sky between the planets), so 59 % of its bytes are repeats.

```bash
python3 tools/fig_loader.py unpack --work work/docs/docA/c1 --window 1808:61000-1826:0 \
    --out docs/img/load/picy-unpack.gif
```

## 3.5 The stages in `c1`

```mermaid
flowchart TD
  A["power-on, LOAD in the ROM: blocks 1-2, the BASIC line 10"] --> B["LOAD CODE: block 4, the loader at $FC00 (ROM LD-BYTES, fast in c1)"]
  B -- "frame 250 T 34 665: RANDOMIZE USR 64512" --> C["Decrypt $FC00: the XOR chain over $FC13-$FEA2"]
  C -- "frame 251 T 4 431" --> D["Start $FE3A: DI, the attributes black"]
  D --> E["LoadFile: header 42 (taken by frame 515), then 4096 bytes at $8000"]
  E -- "frame 1808 T 61 301: CALL $8001" --> F["picy: the probe at $4000, the screen cleared and unpacked"]
  F -- "frame 1825 T 12 550: RET" --> G["LoadFile: header 42 (taken at frame 2080), then 37 536 bytes at $6590"]
  G -- "frame 12 364 T 38 072: LDIR to $5B00, JP $5B00" --> H["MoveStub at $5B00: LDDR $F82F down to $6590 into $FFFF down to $6D60"]
  H -- "frame 12 376 T 62 848: SP $6D5E, EI, JP $6D60" --> I["the game: Start $6D60"]
```

The counter runs during both data blocks: frames 665-1808 for the screen (128 units), 2081-12 364 for the code
(1173). The `LDDR` of 37 536 bytes (21 T a byte, 788 256 T without contention) takes about 12 frames, the last stage
before the game.

`re_session.py stages --work work/c1` lists the code arrivals; each is a stage of 3.3:

| Stage | Entered at | Frame, T | Written by | Entered from | What |
| --- | --- | --- | --- | --- | --- |
| 0 | `$FC00` | 250, 34 665 | `$0802` (the ROM's LD-BYTES, fast load) | `$34BB` (`USR`) | the loader as the tape holds it |
| 1 | `$FC13` | 251, 4 431 | `$FC0B` (the XOR chain) | `$FC11` | the decrypted loader |
| 2 | `$8001` | 1 808, 61 301 | `$FCE7` (the loader's LD-BYTES) | `$FE4B` | the picy unpacker |
| 3 | `$4000` | 1 808, 61 434 | `$8017` | `$801A` | two bytes the unpacker writes into the screen and calls to find its own address (3.4, Where am I) |
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

```mermaid
flowchart LR
  ANN["src/game/game.ann"] -->|kit/mkgame.py| GASM["src/game/*.asm"]
  RES["src/res/"] -->|res_formats.py build| BRES["build/res/"]
  BRES -->|INCBIN| GASM
  GASM -->|sjasmplus| GAME["game.bin: $6D60-$FFFF"]
  LASM["src/tape/loader.asm"] -->|sjasmplus| PLAIN["loader-plain.bin"]
  PLAIN -->|xorchain.py encrypt| LOADER["loader.bin"]
  BRES -->|"picy.py pack loading.scr"| STREAMS["the three streams"]
  STREAMS --> PASM["src/tape/picy.asm"]
  PASM -->|sjasmplus| PICY["picy.bin"]
  BAS["src/tape/basic.asm"] -->|sjasmplus| BASIC["basic.bin"]
  TXT["src/tape/exolon-tzx.txt"] --> TZX["tools/tzx.py: build/Exolon.tzx"]
  BASIC --> TZX
  LOADER --> TZX
  PICY --> TZX
  GAME --> TZX
  TZX -->|cmp| ORIG["orig/Exolon.tzx.zip"]
```

- **A box** is a file, **an arrow** the tool that makes the next file (the steps of `tools/build.sh` in order).
- `kit/mkgame.py` runs before the build, not inside it: it writes `src/game/*.asm` from the annotations and installs
  them only when sjasmplus gives the original image.
- The two transforms of the tape are reversed in the build: the XOR chain (`xorchain.py encrypt`) and the picy
  packer (`picy.py pack`, Zynaps' repeat rule).

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
